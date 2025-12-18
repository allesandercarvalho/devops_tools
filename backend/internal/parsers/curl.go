package parsers

import (
	"bufio"
	"regexp"
	"strconv"
	"strings"

	"github.com/devopstools/backend/internal/models"
)

// ParseCurlVerboseOutput parses curl verbose output to extract response details
func ParseCurlVerboseOutput(output string) (*models.CurlResponse, error) {
	response := &models.CurlResponse{
		Headers: make(map[string][]string),
	}

	scanner := bufio.NewScanner(strings.NewReader(output))
	inResponseHeaders := false
	bodyLines := []string{}

	for scanner.Scan() {
		line := scanner.Text()

		// Status line (e.g., "< HTTP/1.1 200 OK")
		if strings.HasPrefix(line, "< HTTP/") {
			inResponseHeaders = true
			parts := strings.SplitN(line, " ", 3)
			if len(parts) >= 3 {
				statusCode, err := strconv.Atoi(parts[1])
				if err == nil {
					response.StatusCode = statusCode
					response.StatusText = parts[2]
				}
			}
			continue
		}

		// Response headers (lines starting with "< ")
		if inResponseHeaders && strings.HasPrefix(line, "< ") {
			headerLine := strings.TrimPrefix(line, "< ")
			if headerLine == "" {
				// Empty line marks end of headers
				inResponseHeaders = false
				continue
			}

			parts := strings.SplitN(headerLine, ":", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])
				response.Headers[key] = append(response.Headers[key], value)

				// Extract content-type and content-length
				if strings.ToLower(key) == "content-type" {
					response.ContentType = value
				}
				if strings.ToLower(key) == "content-length" {
					if length, err := strconv.ParseInt(value, 10, 64); err == nil {
						response.ContentLength = length
					}
				}
			}
			continue
		}

		// Body (lines that don't start with < or >)
		if !inResponseHeaders && !strings.HasPrefix(line, "<") && !strings.HasPrefix(line, ">") && !strings.HasPrefix(line, "*") && !strings.HasPrefix(line, "{") {
			// Skip curl metadata lines
			continue
		}

		// Capture body content (everything else after headers)
		if !inResponseHeaders && !strings.HasPrefix(line, "<") && !strings.HasPrefix(line, ">") && !strings.HasPrefix(line, "*") {
			bodyLines = append(bodyLines, line)
		}
	}

	response.Body = strings.Join(bodyLines, "\n")

	return response, nil
}

// ParseCurlOutput parses standard curl output (non-verbose)
func ParseCurlOutput(output, headerOutput string) (*models.CurlResponse, error) {
	response := &models.CurlResponse{
		Headers: make(map[string][]string),
		Body:    output,
	}

	// Parse headers from header output
	scanner := bufio.NewScanner(strings.NewReader(headerOutput))
	firstLine := true

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// First line is status line
		if firstLine {
			firstLine = false
			// HTTP/1.1 200 OK
			parts := strings.SplitN(line, " ", 3)
			if len(parts) >= 2 {
				statusCode, err := strconv.Atoi(parts[1])
				if err == nil {
					response.StatusCode = statusCode
					if len(parts) >= 3 {
						response.StatusText = parts[2]
					}
				}
			}
			continue
		}

		// Parse headers
		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			response.Headers[key] = append(response.Headers[key], value)

			if strings.ToLower(key) == "content-type" {
				response.ContentType = value
			}
			if strings.ToLower(key) == "content-length" {
				if length, err := strconv.ParseInt(value, 10, 64); err == nil {
					response.ContentLength = length
				}
			}
		}
	}

	return response, nil
}

// ExtractTimingFromCurl extracts timing information from curl output
func ExtractTimingFromCurl(output string) int64 {
	// Look for time_total in curl output
	re := regexp.MustCompile(`time_total:\s*([0-9.]+)`)
	matches := re.FindStringSubmatch(output)
	if len(matches) > 1 {
		if timeFloat, err := strconv.ParseFloat(matches[1], 64); err == nil {
			return int64(timeFloat * 1000) // Convert to milliseconds
		}
	}
	return 0
}
