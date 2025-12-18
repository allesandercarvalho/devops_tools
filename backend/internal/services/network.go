package services

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os/exec"
	"regexp"
	"strings"
	"time"

	"github.com/devopstools/backend/internal/logger"
	"github.com/devopstools/backend/internal/models"
	"github.com/devopstools/backend/internal/parsers"
	"github.com/devopstools/backend/internal/validators"
	"github.com/google/uuid"
)

// NetworkToolService handles network tool executions
type NetworkToolService struct {
}

// NewNetworkToolService creates a new network tool service
func NewNetworkToolService() *NetworkToolService {
	return &NetworkToolService{}
}

// ExecutePing executes ping command
func (s *NetworkToolService) ExecutePing(target string, count int, timeout int) (*models.NetworkToolExecution, error) {
	// Validate
	target = validators.SanitizeTarget(target)
	if !validators.IsValidTarget(target) {
		return nil, fmt.Errorf("invalid target: %s", target)
	}
	count = validators.ValidateCount(count)
	timeout = validators.ValidateTimeout(timeout)

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "ping",
		Target:    target,
		Args:      []string{"-c", fmt.Sprintf("%d", count), "-W", fmt.Sprintf("%d", timeout), target},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing ping", logger.WithFields(map[string]interface{}{
		"target": target,
		"count":  count,
	}).Data)

	// Execute command
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeout+5)*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "ping", execution.Args...)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse output
	result, parseErr := parsers.ParsePingOutput(string(output))
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

// ExecuteDNSLookup executes DNS lookup
func (s *NetworkToolService) ExecuteDNSLookup(target string, queryType string, server string) (*models.NetworkToolExecution, error) {
	// Validate
	target = validators.SanitizeTarget(target)
	if !validators.IsValidTarget(target) {
		return nil, fmt.Errorf("invalid target: %s", target)
	}

	queryType = validators.SanitizeTarget(queryType)
	if !validators.IsValidDNSType(queryType) {
		queryType = "A" // Default to A record
	}

	// Build args
	args := []string{target, queryType}
	if server != "" {
		server = validators.SanitizeTarget(server)
		if validators.IsValidIP(server) {
			args = append(args, fmt.Sprintf("@%s", server))
		}
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "dig",
		Target:    target,
		Args:      args,
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing DNS lookup", logger.WithFields(map[string]interface{}{
		"target": target,
		"type":   queryType,
	}).Data)

	// Execute command
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "dig", args...)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse output
	result, parseErr := parsers.ParseDigOutput(string(output))
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

// ExecuteTraceroute executes traceroute command
func (s *NetworkToolService) ExecuteTraceroute(target string, maxHops int) (*models.NetworkToolExecution, error) {
	// Validate
	target = validators.SanitizeTarget(target)
	if !validators.IsValidTarget(target) {
		return nil, fmt.Errorf("invalid target: %s", target)
	}

	if maxHops < 1 || maxHops > 64 {
		maxHops = 30 // Default
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "traceroute",
		Target:    target,
		Args:      []string{"-m", fmt.Sprintf("%d", maxHops), target},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing traceroute", logger.WithFields(map[string]interface{}{
		"target":   target,
		"max_hops": maxHops,
	}).Data)

	// Execute command
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "traceroute", execution.Args...)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse output
	result, parseErr := parsers.ParseTracerouteOutput(string(output))
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

// CheckTCPPort checks if a TCP port is open
func (s *NetworkToolService) CheckTCPPort(host string, port int, timeout int) (*models.NetworkToolExecution, error) {
	// Validate
	host = validators.SanitizeTarget(host)
	if !validators.IsValidTarget(host) {
		return nil, fmt.Errorf("invalid host: %s", host)
	}

	if !validators.IsValidPort(port) {
		return nil, fmt.Errorf("invalid port: %d", port)
	}

	timeout = validators.ValidateTimeout(timeout)

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "tcp-check",
		Target:    fmt.Sprintf("%s:%d", host, port),
		Args:      []string{host, fmt.Sprintf("%d", port)},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Checking TCP port", logger.WithFields(map[string]interface{}{
		"host": host,
		"port": port,
	}).Data)

	// Check port
	start := time.Now()
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), time.Duration(timeout)*time.Second)
	duration := time.Since(start)

	result := &models.TCPPortResult{
		Host:   host,
		Port:   port,
		Open:   err == nil,
		TimeMs: duration.Milliseconds(),
	}

	if conn != nil {
		conn.Close()
	}

	execution.ParsedResult = result
	execution.Output = fmt.Sprintf("Port %d on %s is %s (checked in %dms)",
		port, host, map[bool]string{true: "OPEN", false: "CLOSED"}[result.Open], result.TimeMs)

	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()
	execution.Status = "completed"

	return execution, nil
}

// ExecuteHTTPRequest executes HTTP request
func (s *NetworkToolService) ExecuteHTTPRequest(method, url string, headers map[string]string, body string, timeout int) (*models.NetworkToolExecution, error) {
	// Validate
	if !validators.IsValidURL(url) {
		return nil, fmt.Errorf("invalid URL: %s", url)
	}

	timeout = validators.ValidateTimeout(timeout)

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "http-request",
		Target:    url,
		Args:      []string{method, url},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing HTTP request", logger.WithFields(map[string]interface{}{
		"method": method,
		"url":    url,
	}).Data)

	// Create HTTP client
	client := &http.Client{
		Timeout: time.Duration(timeout) * time.Second,
	}

	// Create request
	var bodyReader io.Reader
	if body != "" {
		bodyReader = strings.NewReader(body)
	}

	req, err := http.NewRequest(method, url, bodyReader)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("failed to create request: %v", err)
		return execution, err
	}

	// Add headers
	for k, v := range headers {
		req.Header.Add(k, v)
	}

	// Execute request
	resp, err := client.Do(req)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		execution.Status = "failed"
		execution.Error = fmt.Sprintf("failed to read response body: %v", err)
		return execution, err
	}

	execution.Output = string(respBody)
	execution.Status = "completed"

	// Parse result (basic info)
	execution.ParsedResult = map[string]interface{}{
		"status_code": resp.StatusCode,
		"status":      resp.Status,
		"proto":       resp.Proto,
		"headers":     resp.Header,
		"body_size":   len(respBody),
	}

	return execution, nil
}

// ExecuteNmap executes nmap scan
// ExecuteNmap executes nmap scan with advanced options
func (s *NetworkToolService) ExecuteNmap(target string, scanType string, options map[string]interface{}) (*models.NetworkToolExecution, error) {
	// Validate
	target = validators.SanitizeTarget(target)
	if !validators.IsValidTarget(target) {
		return nil, fmt.Errorf("invalid target: %s", target)
	}

	// Helper to safely append args
	args := []string{}

	// Timing Template
	if timing, ok := options["timing"].(string); ok && timing != "" {
		if isValidTiming(timing) {
			args = append(args, "-"+timing)
		}
	} else {
		args = append(args, "-T3") // Default
	}

	// Scan Type
	switch scanType {
	case "-sS": // TCP SYN
		args = append(args, "-sS")
	case "-sT": // Connect
		args = append(args, "-sT")
	case "-sU": // UDP
		args = append(args, "-sU")
	case "-sA": // ACK
		args = append(args, "-sA")
	case "-sX": // Xmas
		args = append(args, "-sX")
	case "-sN": // Null
		args = append(args, "-sN")
	case "-sF": // FIN
		args = append(args, "-sF")
		// legacy support
	case "quick":
		args = append(args, "-F")
	case "full":
		args = append(args, "-p-")
	case "version":
		args = append(args, "-sV")
	case "os":
		args = append(args, "-O")
	case "custom":
		// do nothing, flags handled elsewhere
	default:
		// Default to SYN scan if nothing specified
		if scanType != "custom" {
			args = append(args, "-sS")
		}
	}

	// Discovery Options
	if val, ok := options["disable_ping"].(bool); ok && val {
		args = append(args, "-Pn")
	}
	if val, ok := options["arp_discovery"].(bool); ok && val {
		args = append(args, "-PR")
	}
	if val, ok := options["udp_discovery"].(bool); ok && val {
		args = append(args, "-PU")
	}
	if val, ok := options["tcp_syn_discovery"].(bool); ok && val {
		args = append(args, "-PS")
	}
	if val, ok := options["icmp_echo"].(bool); ok && val {
		args = append(args, "-PE")
	}
	if val, ok := options["traceroute"].(bool); ok && val {
		args = append(args, "--traceroute")
	}

	// Ports
	if ports, ok := options["ports"].(string); ok && ports != "" {
		// Simple validation to prevent command injection
		if isValidPortSpec(ports) {
			args = append(args, "-p", ports)
		}
	} else if portsMode, ok := options["ports_mode"].(string); ok {
		switch portsMode {
		case "top100":
			args = append(args, "--top-ports", "100")
		case "top1000":
			args = append(args, "--top-ports", "1000")
		case "all":
			args = append(args, "-p-")
		}
	}

	// Version & OS
	if val, ok := options["version_detection"].(bool); ok && val {
		args = append(args, "-sV")
	}
	if val, ok := options["os_detection"].(bool); ok && val {
		args = append(args, "-O")
	}

	// Append target last
	args = append(args, target)

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "nmap",
		Target:    target,
		Args:      args,
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing nmap", logger.WithFields(map[string]interface{}{
		"target": target,
		"args":   args,
	}).Data)

	// Execute command (requires root for some scans, assumed running as root or caps set)
	// Increasing timeout for advanced scans
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "nmap", args...)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		// Still return execution so user can see output (e.g. "needs root privileges")
		return execution, err
	}

	// Parse output
	result, parseErr := parsers.ParseNmapOutput(string(output))
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

func isValidTiming(t string) bool {
	switch t {
	case "T0", "T1", "T2", "T3", "T4", "T5":
		return true
	}
	return false
}

func isValidPortSpec(p string) bool {
	// Basic check for chars allowed in port spec: digits, commas, dashes, whitespace
	matched, _ := regexp.MatchString(`^[\d\s,-]+$`, p)
	return matched
}

// ExecuteWhois executes whois lookup
func (s *NetworkToolService) ExecuteWhois(domain string) (*models.NetworkToolExecution, error) {
	// Validate
	domain = validators.SanitizeTarget(domain)
	if !validators.IsValidDomain(domain) {
		return nil, fmt.Errorf("invalid domain: %s", domain)
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "whois",
		Target:    domain,
		Args:      []string{domain},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing whois", logger.WithFields(map[string]interface{}{
		"domain": domain,
	}).Data)

	// Execute command
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "whois", domain)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse output
	result, parseErr := parsers.ParseWhoisOutput(string(output))
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

// InspectTLS inspects TLS certificate
func (s *NetworkToolService) InspectTLS(host string, port int) (*models.NetworkToolExecution, error) {
	// Validate
	host = validators.SanitizeTarget(host)
	if !validators.IsValidTarget(host) {
		return nil, fmt.Errorf("invalid host: %s", host)
	}

	if !validators.IsValidPort(port) {
		return nil, fmt.Errorf("invalid port: %d", port)
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "tls-inspect",
		Target:    fmt.Sprintf("%s:%d", host, port),
		Args:      []string{host, fmt.Sprintf("%d", port)},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Inspecting TLS", logger.WithFields(map[string]interface{}{
		"host": host,
		"port": port,
	}).Data)

	// Execute TLS inspection using openssl
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "openssl", "s_client", "-connect", fmt.Sprintf("%s:%d", host, port), "-servername", host)
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse TLS certificate info
	result := parsers.ParseTLSOutput(string(output), host, port)
	execution.ParsedResult = result
	execution.Status = "completed"
	return execution, nil
}

// LookupGeoIP performs GeoIP lookup using ip-api.com
func (s *NetworkToolService) LookupGeoIP(ip string) (*models.NetworkToolExecution, error) {
	// Validate
	ip = validators.SanitizeTarget(ip)
	if !validators.IsValidIP(ip) {
		return nil, fmt.Errorf("invalid IP: %s", ip)
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "geoip",
		Target:    ip,
		Args:      []string{ip},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Looking up GeoIP", logger.WithFields(map[string]interface{}{
		"ip": ip,
	}).Data)

	// Use ip-api.com free API
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "curl", "-s", fmt.Sprintf("http://ip-api.com/json/%s", ip))
	output, err := cmd.CombinedOutput()

	execution.Output = string(output)
	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, err
	}

	// Parse GeoIP result
	result, parseErr := parsers.ParseGeoIPOutput(string(output), ip)
	if parseErr == nil {
		execution.ParsedResult = result
	}

	execution.Status = "completed"
	return execution, nil
}

// ExecuteDNSPropagation checks DNS propagation across multiple global resolvers
func (s *NetworkToolService) ExecuteDNSPropagation(domain, recordType string) (*models.NetworkToolExecution, error) {
	// Validate
	domain = validators.SanitizeTarget(domain)
	if !validators.IsValidTarget(domain) {
		return nil, fmt.Errorf("invalid domain: %s", domain)
	}

	// Create execution
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "dns-propagation",
		Target:    domain,
		Args:      []string{domain, recordType},
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Checking DNS propagation", logger.WithFields(map[string]interface{}{
		"domain": domain,
		"type":   recordType,
	}).Data)

	// List of global DNS servers
	resolvers := map[string]string{
		"Google (US)":         "8.8.8.8:53",
		"Cloudflare (Global)": "1.1.1.1:53",
		"OpenDNS (Global)":    "208.67.222.222:53",
		"Quad9 (Global)":      "9.9.9.9:53",
		"Level3 (US)":         "4.2.2.1:53",
		"Verisign (US)":       "64.6.64.6:53",
		"Comodo (Global)":     "8.26.56.26:53",
		"DNS.Watch (Germany)": "84.200.69.80:53",
		"Yandex (Russia)":     "77.88.8.8:53",
		"AdGuard (Global)":    "94.140.14.14:53",
	}

	results := make(map[string]interface{})

	// Perform lookups in parallel
	type lookupResult struct {
		Server string
		Result []string
		Error  string
	}

	ch := make(chan lookupResult, len(resolvers))

	for name, addr := range resolvers {
		go func(serverName, serverAddr string) {
			r := &net.Resolver{
				PreferGo: true,
				Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
					d := net.Dialer{
						Timeout: 2 * time.Second,
					}
					return d.DialContext(ctx, "udp", serverAddr)
				},
			}

			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()

			var res []string
			var err error

			switch recordType {
			case "A":
				ips, e := r.LookupHost(ctx, domain)
				res = ips
				err = e
			case "MX":
				mxs, e := r.LookupMX(ctx, domain)
				for _, mx := range mxs {
					res = append(res, fmt.Sprintf("%d %s", mx.Pref, mx.Host))
				}
				err = e
			case "TXT":
				txts, e := r.LookupTXT(ctx, domain)
				res = txts
				err = e
			case "NS":
				nss, e := r.LookupNS(ctx, domain)
				for _, ns := range nss {
					res = append(res, ns.Host)
				}
				err = e
			case "CNAME":
				cname, e := r.LookupCNAME(ctx, domain)
				res = []string{cname}
				err = e
			default:
				// Default to Host lookup (A/AAAA)
				ips, e := r.LookupHost(ctx, domain)
				res = ips
				err = e
			}

			if err != nil {
				ch <- lookupResult{Server: serverName, Error: err.Error()}
			} else {
				ch <- lookupResult{Server: serverName, Result: res}
			}
		}(name, addr)
	}

	// Collect results
	for i := 0; i < len(resolvers); i++ {
		res := <-ch
		if res.Error != "" {
			results[res.Server] = map[string]string{"status": "failed", "error": res.Error}
		} else {
			results[res.Server] = map[string]interface{}{"status": "success", "records": res.Result}
		}
	}

	execution.ParsedResult = results
	execution.Output = fmt.Sprintf("Checked %d DNS servers for %s %s", len(resolvers), recordType, domain)

	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = now.Sub(execution.StartedAt).Milliseconds()
	execution.Status = "completed"

	return execution, nil
}
