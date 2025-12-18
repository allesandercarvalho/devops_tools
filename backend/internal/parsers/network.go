package parsers

import (
	"encoding/json"
	"regexp"
	"strconv"
	"strings"

	"github.com/devopstools/backend/internal/models"
)

// ParsePingOutput parses ping command output
func ParsePingOutput(output string) (*models.PingResult, error) {
	result := &models.PingResult{}

	// Parse "5 packets transmitted, 5 received, 0% packet loss"
	packetRegex := regexp.MustCompile(`(\d+) packets transmitted, (\d+) (?:packets )?received, ([\d.]+)% packet loss`)
	if matches := packetRegex.FindStringSubmatch(output); len(matches) == 4 {
		result.PacketsSent, _ = strconv.Atoi(matches[1])
		result.PacketsReceived, _ = strconv.Atoi(matches[2])
		result.PacketLoss, _ = strconv.ParseFloat(matches[3], 64)
	}

	// Parse "rtt min/avg/max/stddev = 10.123/15.456/20.789/2.345 ms"
	// or "round-trip min/avg/max/stddev = 10.123/15.456/20.789/2.345 ms" (macOS)
	rttRegex := regexp.MustCompile(`(?:rtt|round-trip) min/avg/max/(?:stddev|mdev) = ([\d.]+)/([\d.]+)/([\d.]+)/([\d.]+) ms`)
	if matches := rttRegex.FindStringSubmatch(output); len(matches) == 5 {
		result.MinRTT, _ = strconv.ParseFloat(matches[1], 64)
		result.AvgRTT, _ = strconv.ParseFloat(matches[2], 64)
		result.MaxRTT, _ = strconv.ParseFloat(matches[3], 64)
		result.StdDevRTT, _ = strconv.ParseFloat(matches[4], 64)
	}

	return result, nil
}

// ParseDigOutput parses dig command output
func ParseDigOutput(output string) (*models.DNSResult, error) {
	result := &models.DNSResult{
		Answers: []string{},
	}

	lines := strings.Split(output, "\n")
	inAnswerSection := false

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Detect answer section
		if strings.Contains(line, "ANSWER SECTION:") {
			inAnswerSection = true
			continue
		}

		// End of answer section
		if inAnswerSection && (strings.HasPrefix(line, ";") || line == "") {
			if !strings.Contains(line, "ANSWER SECTION:") {
				inAnswerSection = false
			}
			continue
		}

		// Parse answer lines
		if inAnswerSection && !strings.HasPrefix(line, ";") {
			fields := strings.Fields(line)
			if len(fields) >= 5 {
				// Format: domain TTL CLASS TYPE answer
				result.QueryType = fields[3]
				result.Answers = append(result.Answers, fields[4])
			}
		}

		// Parse query time
		if strings.Contains(line, "Query time:") {
			timeRegex := regexp.MustCompile(`Query time: (\d+) msec`)
			if matches := timeRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.QueryTime, _ = strconv.Atoi(matches[1])
			}
		}

		// Parse server
		if strings.Contains(line, "SERVER:") {
			serverRegex := regexp.MustCompile(`SERVER: ([^\s#]+)`)
			if matches := serverRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.Server = matches[1]
			}
		}
	}

	return result, nil
}

// ParseTracerouteOutput parses traceroute command output
func ParseTracerouteOutput(output string) (*models.TracerouteResult, error) {
	result := &models.TracerouteResult{
		Hops: []models.TracerouteHop{},
	}

	lines := strings.Split(output, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// Skip header lines
		if strings.Contains(line, "traceroute to") || strings.Contains(line, "hops max") {
			continue
		}

		// Parse hop line: " 1  router.local (192.168.1.1)  1.234 ms  1.456 ms  1.789 ms"
		hopRegex := regexp.MustCompile(`^\s*(\d+)\s+(?:([^\s]+)\s+)?\(?([\d.]+)\)?(?:\s+([\d.]+)\s+ms)?(?:\s+([\d.]+)\s+ms)?(?:\s+([\d.]+)\s+ms)?`)
		if matches := hopRegex.FindStringSubmatch(line); len(matches) >= 4 {
			hop := models.TracerouteHop{}
			hop.Number, _ = strconv.Atoi(matches[1])
			hop.Host = matches[2]
			hop.IP = matches[3]

			// Parse RTT values
			if len(matches) > 4 && matches[4] != "" {
				hop.RTT1, _ = strconv.ParseFloat(matches[4], 64)
			}
			if len(matches) > 5 && matches[5] != "" {
				hop.RTT2, _ = strconv.ParseFloat(matches[5], 64)
			}
			if len(matches) > 6 && matches[6] != "" {
				hop.RTT3, _ = strconv.ParseFloat(matches[6], 64)
			}

			// Calculate average
			count := 0
			sum := 0.0
			if hop.RTT1 > 0 {
				sum += hop.RTT1
				count++
			}
			if hop.RTT2 > 0 {
				sum += hop.RTT2
				count++
			}
			if hop.RTT3 > 0 {
				sum += hop.RTT3
				count++
			}
			if count > 0 {
				hop.AvgRTT = sum / float64(count)
			}

			result.Hops = append(result.Hops, hop)
		}
	}

	return result, nil
}

// ParseNmapOutput parses nmap command output
func ParseNmapOutput(output string) (*models.NmapResult, error) {
	result := &models.NmapResult{
		Hosts: []models.NmapHost{},
	}

	lines := strings.Split(output, "\n")
	var currentHost *models.NmapHost

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Parse "Nmap scan report for hostname (IP)"
		if strings.HasPrefix(line, "Nmap scan report for") {
			hostRegex := regexp.MustCompile(`Nmap scan report for ([^\s]+)(?: \(([^\)]+)\))?`)
			if matches := hostRegex.FindStringSubmatch(line); len(matches) >= 2 {
				if currentHost != nil {
					result.Hosts = append(result.Hosts, *currentHost)
				}
				currentHost = &models.NmapHost{
					Hostname: matches[1],
					Ports:    []models.NmapPort{},
				}
				if len(matches) > 2 && matches[2] != "" {
					currentHost.IP = matches[2]
				}
			}
		}

		// Parse port line: "22/tcp   open  ssh"
		if currentHost != nil && strings.Contains(line, "/tcp") {
			portRegex := regexp.MustCompile(`(\d+)/tcp\s+(\w+)\s+(.+)`)
			if matches := portRegex.FindStringSubmatch(line); len(matches) == 4 {
				portNum, _ := strconv.Atoi(matches[1])
				currentHost.Ports = append(currentHost.Ports, models.NmapPort{
					Port:    portNum,
					State:   matches[2],
					Service: matches[3],
				})
			}
		}

		// Parse OS detection
		if strings.Contains(line, "OS details:") {
			osRegex := regexp.MustCompile(`OS details: (.+)`)
			if matches := osRegex.FindStringSubmatch(line); len(matches) == 2 {
				if currentHost != nil {
					currentHost.OS = matches[1]
				}
			}
		}
	}

	if currentHost != nil {
		result.Hosts = append(result.Hosts, *currentHost)
	}

	return result, nil
}

// ParseWhoisOutput parses whois command output
func ParseWhoisOutput(output string) (*models.WhoisResult, error) {
	result := &models.WhoisResult{
		RawData: output,
	}

	lines := strings.Split(output, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "%") || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch strings.ToLower(key) {
		case "domain name", "domain":
			result.Domain = value
		case "registrar":
			result.Registrar = value
		case "creation date", "created":
			result.CreatedDate = value
		case "expiration date", "expiry date", "expires":
			result.ExpiryDate = value
		case "updated date", "last updated", "modified":
			result.UpdatedDate = value
		case "name server", "nserver":
			result.NameServers = append(result.NameServers, value)
		case "registrant organization", "registrant":
			if result.Registrant == "" {
				result.Registrant = value
			}
		}
	}

	return result, nil
}

// ParseTLSOutput parses openssl s_client output
func ParseTLSOutput(output string, host string, port int) *models.TLSResult {
	result := &models.TLSResult{
		Host:     host,
		Port:     port,
		DNSNames: []string{},
		IsValid:  false,
	}

	lines := strings.Split(output, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Parse protocol version
		if strings.Contains(line, "Protocol") {
			versionRegex := regexp.MustCompile(`Protocol\s*:\s*(.+)`)
			if matches := versionRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.Version = strings.TrimSpace(matches[1])
			}
		}

		// Parse cipher
		if strings.Contains(line, "Cipher") {
			cipherRegex := regexp.MustCompile(`Cipher\s*:\s*(.+)`)
			if matches := cipherRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.Cipher = strings.TrimSpace(matches[1])
			}
		}

		// Parse issuer
		if strings.Contains(line, "issuer=") {
			issuerRegex := regexp.MustCompile(`issuer=(.+)`)
			if matches := issuerRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.Issuer = strings.TrimSpace(matches[1])
			}
		}

		// Parse subject
		if strings.Contains(line, "subject=") {
			subjectRegex := regexp.MustCompile(`subject=(.+)`)
			if matches := subjectRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.Subject = strings.TrimSpace(matches[1])
			}
		}

		// Parse validity dates
		if strings.Contains(line, "notBefore=") {
			dateRegex := regexp.MustCompile(`notBefore=(.+)`)
			if matches := dateRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.ValidFrom = strings.TrimSpace(matches[1])
			}
		}

		if strings.Contains(line, "notAfter=") {
			dateRegex := regexp.MustCompile(`notAfter=(.+)`)
			if matches := dateRegex.FindStringSubmatch(line); len(matches) == 2 {
				result.ValidTo = strings.TrimSpace(matches[1])
			}
		}

		// Parse DNS names
		if strings.Contains(line, "DNS:") {
			dnsRegex := regexp.MustCompile(`DNS:([^,\s]+)`)
			matches := dnsRegex.FindAllStringSubmatch(line, -1)
			for _, match := range matches {
				if len(match) == 2 {
					result.DNSNames = append(result.DNSNames, match[1])
				}
			}
		}

		// Check if verification succeeded
		if strings.Contains(line, "Verify return code: 0") {
			result.IsValid = true
		}
	}

	return result
}

// ParseGeoIPOutput parses ip-api.com JSON response
func ParseGeoIPOutput(output string, ip string) (*models.GeoIPResult, error) {
	var data map[string]interface{}
	if err := json.Unmarshal([]byte(output), &data); err != nil {
		return nil, err
	}

	result := &models.GeoIPResult{
		IP: ip,
	}

	if country, ok := data["country"].(string); ok {
		result.Country = country
	}
	if countryCode, ok := data["countryCode"].(string); ok {
		result.CountryCode = countryCode
	}
	if region, ok := data["regionName"].(string); ok {
		result.Region = region
	}
	if city, ok := data["city"].(string); ok {
		result.City = city
	}
	if lat, ok := data["lat"].(float64); ok {
		result.Latitude = lat
	}
	if lon, ok := data["lon"].(float64); ok {
		result.Longitude = lon
	}
	if isp, ok := data["isp"].(string); ok {
		result.ISP = isp
	}
	if org, ok := data["org"].(string); ok {
		result.Organization = org
	}

	return result, nil
}
