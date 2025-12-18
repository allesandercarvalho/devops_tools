package services

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/devopstools/backend/internal/logger"
)

// AWSService handles AWS CLI command execution
type AWSService struct{}

// NewAWSService creates a new AWS service instance
func NewAWSService() *AWSService {
	return &AWSService{}
}

// CommandRequest represents an AWS CLI command request
type CommandRequest struct {
	Command string `json:"command"`
	Profile string `json:"profile,omitempty"`
	Region  string `json:"region,omitempty"`
}

// CommandResult represents the result of an AWS CLI command execution
type CommandResult struct {
	Command   string    `json:"command"`
	Stdout    string    `json:"stdout"`
	Stderr    string    `json:"stderr"`
	ExitCode  int       `json:"exit_code"`
	Duration  float64   `json:"duration"`
	Timestamp time.Time `json:"timestamp"`
	Success   bool      `json:"success"`
}

// ValidateCommand validates that the AWS CLI command is safe to execute
func (s *AWSService) ValidateCommand(cmd string) error {
	// Remove leading/trailing whitespace
	cmd = strings.TrimSpace(cmd)

	// Must start with "aws"
	if !strings.HasPrefix(cmd, "aws ") {
		return fmt.Errorf("command must start with 'aws'")
	}

	// Blacklist dangerous commands
	dangerousPatterns := []string{
		"rm -rf",
		"delete-bucket --force",
		"terminate-instances",
		"delete-db-instance --skip-final-snapshot",
		"delete-stack",
		"&&",
		"||",
		";",
		"|",
		"`",
		"$(",
	}

	cmdLower := strings.ToLower(cmd)
	for _, pattern := range dangerousPatterns {
		if strings.Contains(cmdLower, pattern) {
			return fmt.Errorf("command contains potentially dangerous pattern: %s", pattern)
		}
	}

	return nil
}

// ExecuteCommand executes an AWS CLI command with optional profile and region
func (s *AWSService) ExecuteCommand(ctx context.Context, req CommandRequest) (*CommandResult, error) {
	startTime := time.Now()
	result := &CommandResult{
		Command:   req.Command,
		Timestamp: startTime,
	}

	// Validate command
	if err := s.ValidateCommand(req.Command); err != nil {
		logger.Error("Command validation failed", err)
		result.Stderr = err.Error()
		result.ExitCode = 1
		result.Success = false
		result.Duration = time.Since(startTime).Seconds()
		return result, err
	}

	// Parse command into parts
	parts := strings.Fields(req.Command)
	if len(parts) == 0 {
		err := fmt.Errorf("empty command")
		result.Stderr = err.Error()
		result.ExitCode = 1
		result.Success = false
		result.Duration = time.Since(startTime).Seconds()
		return result, err
	}

	// Add profile if specified
	if req.Profile != "" {
		parts = append(parts, "--profile", req.Profile)
	}

	// Add region if specified
	if req.Region != "" {
		parts = append(parts, "--region", req.Region)
	}

	// Create command
	cmd := exec.CommandContext(ctx, parts[0], parts[1:]...)

	// Execute command
	output, err := cmd.CombinedOutput()
	duration := time.Since(startTime).Seconds()

	result.Duration = duration

	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitErr.ExitCode()
		} else {
			result.ExitCode = 1
		}
		result.Stderr = string(output)
		result.Success = false
		logger.Warn(fmt.Sprintf("AWS command failed: %s", req.Command), nil)
	} else {
		result.ExitCode = 0
		result.Stdout = string(output)
		result.Success = true
		logger.Info(fmt.Sprintf("AWS command executed successfully: %s", req.Command))
	}

	return result, nil
}

// GetAWSVersion returns the installed AWS CLI version
func (s *AWSService) GetAWSVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, "aws", "--version")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("failed to get AWS CLI version: %w", err)
	}
	return strings.TrimSpace(string(output)), nil
}

// ListProfiles returns a list of configured AWS profiles
func (s *AWSService) ListProfiles(ctx context.Context) ([]string, error) {
	cmd := exec.CommandContext(ctx, "aws", "configure", "list-profiles")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("failed to list AWS profiles: %w", err)
	}

	profiles := []string{}
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			profiles = append(profiles, line)
		}
	}

	return profiles, nil
}
