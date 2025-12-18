package validators

import (
	"fmt"
	"net"
	"regexp"
	"strconv"
	"strings"
)

// IsValidIP checks if a string is a valid IP address
func IsValidIP(ip string) bool {
	return net.ParseIP(ip) != nil
}

// IsValidDomain checks if a string is a valid domain name
func IsValidDomain(domain string) bool {
	// Basic domain validation
	domainRegex := regexp.MustCompile(`^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$`)
	return domainRegex.MatchString(domain)
}

// IsValidTarget checks if a string is a valid IP or domain
func IsValidTarget(target string) bool {
	return IsValidIP(target) || IsValidDomain(target)
}

// IsValidPort checks if a port number is valid
func IsValidPort(port int) bool {
	return port > 0 && port <= 65535
}

// IsValidURL checks if a string is a valid URL
func IsValidURL(url string) bool {
	return strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://")
}

// IsValidDNSType checks if a DNS query type is valid
func IsValidDNSType(dnsType string) bool {
	validTypes := map[string]bool{
		"A": true, "AAAA": true, "MX": true, "TXT": true,
		"NS": true, "CNAME": true, "SOA": true, "PTR": true,
		"SRV": true, "CAA": true,
	}
	return validTypes[strings.ToUpper(dnsType)]
}

// SanitizeTarget removes potentially dangerous characters
func SanitizeTarget(target string) string {
	// Remove shell metacharacters
	dangerous := []string{";", "&", "|", "`", "$", "(", ")", "<", ">", "\\", "\"", "'"}
	result := target
	for _, char := range dangerous {
		result = strings.ReplaceAll(result, char, "")
	}
	return result
}

// ValidateCount validates ping/traceroute count parameter
func ValidateCount(count int) int {
	if count < 1 {
		return 1
	}
	if count > 100 {
		return 100
	}
	return count
}

// ValidateTimeout validates timeout parameter (in seconds)
func ValidateTimeout(timeout int) int {
	if timeout < 1 {
		return 5
	}
	if timeout > 60 {
		return 60
	}
	return timeout
}

// ParsePortFromString parses port from string
func ParsePortFromString(portStr string) (int, error) {
	port, err := strconv.Atoi(portStr)
	if err != nil {
		return 0, err
	}
	if !IsValidPort(port) {
		return 0, fmt.Errorf("invalid port: %d", port)
	}
	return port, nil
}
