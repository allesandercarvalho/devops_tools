package services

import (
	"bufio"
	"context"
	"fmt"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

// CommandService handles command execution
type CommandService struct {
	executions map[string]*models.CommandExecution
	mu         sync.RWMutex
	onOutput   func(execID string, output string)
}

// NewCommandService creates a new command service
func NewCommandService() *CommandService {
	return &CommandService{
		executions: make(map[string]*models.CommandExecution),
	}
}

// SetOutputCallback sets the callback for streaming output
func (s *CommandService) SetOutputCallback(callback func(execID string, output string)) {
	s.onOutput = callback
}

// Execute runs a command and streams output
func (s *CommandService) Execute(ctx context.Context, userID, command string, args []string, workDir string) (*models.CommandExecution, error) {
	// Validate command (security)
	if !s.isCommandAllowed(command) {
		return nil, fmt.Errorf("command not allowed: %s", command)
	}

	execution := &models.CommandExecution{
		ID:        uuid.New().String(),
		UserID:    userID,
		Command:   command,
		Args:      args,
		WorkDir:   workDir,
		Status:    "pending",
		StartedAt: time.Now(),
	}

	s.mu.Lock()
	s.executions[execution.ID] = execution
	s.mu.Unlock()

	// Run command in goroutine
	go s.runCommand(ctx, execution)

	return execution, nil
}

// GetExecution retrieves an execution by ID
func (s *CommandService) GetExecution(id string) (*models.CommandExecution, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	exec, ok := s.executions[id]
	if !ok {
		return nil, fmt.Errorf("execution not found: %s", id)
	}
	return exec, nil
}

// runCommand executes the command and streams output
func (s *CommandService) runCommand(ctx context.Context, execution *models.CommandExecution) {
	execution.Status = "running"

	cmd := exec.CommandContext(ctx, execution.Command, execution.Args...)
	if execution.WorkDir != "" {
		cmd.Dir = execution.WorkDir
	}

	// Capture stdout and stderr
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		s.failExecution(execution, fmt.Sprintf("Failed to create stdout pipe: %v", err))
		return
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		s.failExecution(execution, fmt.Sprintf("Failed to create stderr pipe: %v", err))
		return
	}

	// Start command
	if err := cmd.Start(); err != nil {
		s.failExecution(execution, fmt.Sprintf("Failed to start command: %v", err))
		return
	}

	// Stream output
	var wg sync.WaitGroup
	wg.Add(2)

	// Read stdout
	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			s.appendOutput(execution, line+"\n")
			if s.onOutput != nil {
				s.onOutput(execution.ID, line+"\n")
			}
		}
	}()

	// Read stderr
	go func() {
		defer wg.Done()
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()
			s.appendOutput(execution, "[ERROR] "+line+"\n")
			if s.onOutput != nil {
				s.onOutput(execution.ID, "[ERROR] "+line+"\n")
			}
		}
	}()

	// Wait for output readers
	wg.Wait()

	// Wait for command to finish
	err = cmd.Wait()
	endTime := time.Now()
	execution.EndedAt = &endTime
	execution.Duration = endTime.Sub(execution.StartedAt).Milliseconds()

	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			execution.ExitCode = exitErr.ExitCode()
		}
		execution.Status = "failed"
		execution.Error = err.Error()
	} else {
		execution.Status = "success"
		execution.ExitCode = 0
	}
}

// appendOutput adds output to execution
func (s *CommandService) appendOutput(execution *models.CommandExecution, output string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	execution.Output += output
}

// failExecution marks execution as failed
func (s *CommandService) failExecution(execution *models.CommandExecution, errMsg string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	execution.Status = "failed"
	execution.Error = errMsg
	endTime := time.Now()
	execution.EndedAt = &endTime
	execution.Duration = endTime.Sub(execution.StartedAt).Milliseconds()
}

// isCommandAllowed validates if command is allowed (security)
func (s *CommandService) isCommandAllowed(command string) bool {
	// Whitelist of allowed commands
	allowedCommands := []string{
		"aws", "terraform", "kubectl", "argocd", "git",
		"docker", "helm", "gcloud", "az", // Azure CLI
		"ping", "curl", "dig", "nslookup", "traceroute",
	}

	for _, allowed := range allowedCommands {
		if strings.HasPrefix(command, allowed) || command == allowed {
			return true
		}
	}

	return false
}
