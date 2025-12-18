package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"time"

	"github.com/devopstools/backend/internal/logger"
	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

type TerraformService struct{}

func NewTerraformService() *TerraformService {
	return &TerraformService{}
}

// ExecuteCommand executes a generic terraform command
func (s *TerraformService) ExecuteCommand(workDir string, command string, args ...string) (*models.TerraformExecution, error) {
	execution := &models.TerraformExecution{
		ID:        uuid.New().String(),
		Command:   command,
		WorkDir:   workDir,
		Args:      args,
		Status:    "running",
		StartedAt: time.Now(),
	}

	logger.Info("Executing terraform", logger.WithFields(map[string]interface{}{
		"command": command,
		"dir":     workDir,
	}).Data)

	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Second) // 5 min timeout
	defer cancel()

	fullArgs := append([]string{command}, args...)
	cmd := exec.CommandContext(ctx, "terraform", fullArgs...)
	cmd.Dir = workDir

	// For non-interactive commands, we want to capture output
	// For interactive (like apply without auto-approve), we might need streaming,
	// but for now we'll assume non-interactive usage via API
	if command == "apply" || command == "destroy" {
		// Ensure auto-approve if not present, unless it's a plan
		hasAutoApprove := false
		for _, arg := range args {
			if arg == "-auto-approve" {
				hasAutoApprove = true
				break
			}
		}
		if !hasAutoApprove {
			// For safety, maybe we shouldn't auto-add it, but for an API tool usually we do or fail.
			// Let's assume the frontend sends -auto-approve if confirmed.
		}
	}

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

	execution.Status = "completed"
	return execution, nil
}

// GetState returns the current state as JSON
func (s *TerraformService) GetState(workDir string) (*models.TerraformState, error) {
	// Run terraform show -json
	execution, err := s.ExecuteCommand(workDir, "show", "-json")
	if err != nil {
		return nil, err
	}

	var state models.TerraformState
	if err := json.Unmarshal([]byte(execution.Output), &state); err != nil {
		return nil, fmt.Errorf("failed to parse state json: %v", err)
	}

	return &state, nil
}
