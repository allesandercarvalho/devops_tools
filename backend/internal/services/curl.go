package services

import (
	"bytes"
	"context"
	"fmt"
	"net/url"
	"os/exec"
	"strings"
	"time"

	"github.com/devopstools/backend/internal/logger"
	"github.com/devopstools/backend/internal/models"
	"github.com/devopstools/backend/internal/parsers"
	"github.com/devopstools/backend/internal/validators"
	"github.com/google/uuid"
)

// CurlService handles advanced HTTP requests using curl
type CurlService struct{}

// NewCurlService creates a new curl service
func NewCurlService() *CurlService {
	return &CurlService{}
}

// ExecuteCurlRequest executes an advanced HTTP request using curl
func (s *CurlService) ExecuteCurlRequest(req *models.CurlRequest) (*models.NetworkToolExecution, error) {
	// Validate URL
	if !validators.IsValidURL(req.URL) {
		return nil, fmt.Errorf("invalid URL: %s", req.URL)
	}

	// Default timeout
	if req.Timeout <= 0 {
		req.Timeout = 30
	}

	// Build curl command
	curlArgs, err := s.buildCurlCommand(req)
	if err != nil {
		return nil, fmt.Errorf("failed to build curl command: %v", err)
	}

	// Create execution record
	execution := &models.NetworkToolExecution{
		ID:        uuid.New().String(),
		Tool:      "curl",
		Target:    req.URL,
		Args:      curlArgs,
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing curl request", logger.WithFields(map[string]interface{}{
		"method": req.Method,
		"url":    req.URL,
	}).Data)

	// Execute curl command
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(req.Timeout+5)*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "curl", curlArgs...)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	startTime := time.Now()
	err = cmd.Run()
	duration := time.Since(startTime)

	now := time.Now()
	execution.CompletedAt = &now
	execution.DurationMs = duration.Milliseconds()

	// Combine stdout and stderr for full output
	fullOutput := stdout.String()
	if stderr.Len() > 0 {
		fullOutput += "\n--- STDERR ---\n" + stderr.String()
	}

	execution.Output = fullOutput

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
		return execution, fmt.Errorf("curl execution failed: %v", err)
	}

	// Parse curl output
	response, parseErr := s.parseCurlResponse(fullOutput, stderr.String())
	if parseErr != nil {
		logger.Info("Failed to parse curl response", logger.WithFields(map[string]interface{}{
			"error": parseErr.Error(),
		}).Data)
	}

	if response != nil {
		response.TimeMs = duration.Milliseconds()
		response.CurlCommand = s.generateCurlCommand(req)
		execution.ParsedResult = response
	}

	execution.Status = "completed"
	return execution, nil
}

// buildCurlCommand builds the curl command arguments
func (s *CurlService) buildCurlCommand(req *models.CurlRequest) ([]string, error) {
	args := []string{}

	// Method
	if req.Method != "" && req.Method != "GET" {
		args = append(args, "-X", strings.ToUpper(req.Method))
	}

	// URL with query parameters
	finalURL := req.URL
	if len(req.QueryParams) > 0 {
		u, err := url.Parse(req.URL)
		if err != nil {
			return nil, fmt.Errorf("invalid URL: %v", err)
		}

		q := u.Query()
		for key, value := range req.QueryParams {
			q.Add(key, value)
		}
		u.RawQuery = q.Encode()
		finalURL = u.String()
	}

	// Headers
	for key, value := range req.Headers {
		args = append(args, "-H", fmt.Sprintf("%s: %s", key, value))
	}

	// Authentication
	if req.Auth != nil {
		switch req.Auth.Type {
		case "basic":
			if req.Auth.Username != "" && req.Auth.Password != "" {
				args = append(args, "-u", fmt.Sprintf("%s:%s", req.Auth.Username, req.Auth.Password))
			}
		case "bearer":
			if req.Auth.Token != "" {
				args = append(args, "-H", fmt.Sprintf("Authorization: Bearer %s", req.Auth.Token))
			}
		case "apikey":
			if req.Auth.ApiKey != "" {
				headerName := req.Auth.ApiKeyHeader
				if headerName == "" {
					headerName = "X-API-Key"
				}
				args = append(args, "-H", fmt.Sprintf("%s: %s", headerName, req.Auth.ApiKey))
			}
		}
	}

	// Body
	if req.Body != "" {
		switch req.BodyType {
		case "json":
			// Ensure Content-Type is set for JSON
			hasContentType := false
			for key := range req.Headers {
				if strings.ToLower(key) == "content-type" {
					hasContentType = true
					break
				}
			}
			if !hasContentType {
				args = append(args, "-H", "Content-Type: application/json")
			}
			args = append(args, "-d", req.Body)
		case "xml":
			hasContentType := false
			for key := range req.Headers {
				if strings.ToLower(key) == "content-type" {
					hasContentType = true
					break
				}
			}
			if !hasContentType {
				args = append(args, "-H", "Content-Type: application/xml")
			}
			args = append(args, "-d", req.Body)
		case "form":
			// Parse form data and add as -d parameters
			args = append(args, "-d", req.Body)
		default: // raw
			args = append(args, "-d", req.Body)
		}
	}

	// Follow redirects
	if req.FollowRedirects {
		args = append(args, "-L")
	}

	// SSL verification
	if !req.VerifySSL {
		args = append(args, "-k")
	}

	// Timeout
	args = append(args, "--max-time", fmt.Sprintf("%d", req.Timeout))

	// Include response headers in output
	args = append(args, "-i")

	// Silent mode (no progress bar)
	args = append(args, "-s")

	// Show error messages
	args = append(args, "-S")

	// Write timing information
	args = append(args, "-w", "\ntime_total: %{time_total}\n")

	// Add URL as last argument
	args = append(args, finalURL)

	return args, nil
}

// parseCurlResponse parses the curl response
func (s *CurlService) parseCurlResponse(output, stderr string) (*models.CurlResponse, error) {
	// Split headers and body
	parts := strings.SplitN(output, "\r\n\r\n", 2)
	if len(parts) < 2 {
		parts = strings.SplitN(output, "\n\n", 2)
	}

	if len(parts) < 2 {
		return nil, fmt.Errorf("failed to parse response: no header/body separator found")
	}

	headerSection := parts[0]
	bodySection := parts[1]

	// Extract timing info from body section
	timingIdx := strings.Index(bodySection, "\ntime_total:")
	actualBody := bodySection
	if timingIdx > 0 {
		actualBody = bodySection[:timingIdx]
	}

	response, err := parsers.ParseCurlOutput(actualBody, headerSection)
	if err != nil {
		return nil, err
	}

	// Extract timing
	response.TimeMs = parsers.ExtractTimingFromCurl(output)

	return response, nil
}

// generateCurlCommand generates a human-readable curl command for copying
func (s *CurlService) generateCurlCommand(req *models.CurlRequest) string {
	parts := []string{"curl"}

	// Method
	if req.Method != "" && req.Method != "GET" {
		parts = append(parts, fmt.Sprintf("-X %s", strings.ToUpper(req.Method)))
	}

	// URL with query parameters
	finalURL := req.URL
	if len(req.QueryParams) > 0 {
		u, _ := url.Parse(req.URL)
		q := u.Query()
		for key, value := range req.QueryParams {
			q.Add(key, value)
		}
		u.RawQuery = q.Encode()
		finalURL = u.String()
	}

	// Headers
	for key, value := range req.Headers {
		parts = append(parts, fmt.Sprintf("-H '%s: %s'", key, value))
	}

	// Authentication
	if req.Auth != nil {
		switch req.Auth.Type {
		case "basic":
			if req.Auth.Username != "" && req.Auth.Password != "" {
				parts = append(parts, fmt.Sprintf("-u '%s:%s'", req.Auth.Username, req.Auth.Password))
			}
		case "bearer":
			if req.Auth.Token != "" {
				parts = append(parts, fmt.Sprintf("-H 'Authorization: Bearer %s'", req.Auth.Token))
			}
		case "apikey":
			if req.Auth.ApiKey != "" {
				headerName := req.Auth.ApiKeyHeader
				if headerName == "" {
					headerName = "X-API-Key"
				}
				parts = append(parts, fmt.Sprintf("-H '%s: %s'", headerName, req.Auth.ApiKey))
			}
		}
	}

	// Body
	if req.Body != "" {
		// Escape single quotes in body
		escapedBody := strings.ReplaceAll(req.Body, "'", "'\\''")
		parts = append(parts, fmt.Sprintf("-d '%s'", escapedBody))
	}

	// Follow redirects
	if req.FollowRedirects {
		parts = append(parts, "-L")
	}

	// SSL verification
	if !req.VerifySSL {
		parts = append(parts, "-k")
	}

	// Add URL
	parts = append(parts, fmt.Sprintf("'%s'", finalURL))

	return strings.Join(parts, " \\\n  ")
}
