package terraform

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// TerraformState represents Terraform state
type TerraformState struct {
	Version          int                    `json:"version"`
	TerraformVersion string                 `json:"terraform_version"`
	Serial           int                    `json:"serial"`
	Lineage          string                 `json:"lineage"`
	Outputs          map[string]interface{} `json:"outputs"`
	Resources        []TerraformResource    `json:"resources"`
}

// TerraformResource represents a resource in state
type TerraformResource struct {
	Mode       string                 `json:"mode"`
	Type       string                 `json:"type"`
	Name       string                 `json:"name"`
	Provider   string                 `json:"provider"`
	Instances  []interface{}          `json:"instances"`
	Attributes map[string]interface{} `json:"attributes,omitempty"`
}

// TerraformWorkspace represents a workspace
type TerraformWorkspace struct {
	Name    string
	Current bool
}

// ParseTerraformState parses terraform.tfstate file
func ParseTerraformState(statePath string) (*TerraformState, error) {
	cmd := exec.Command("terraform", "show", "-json", statePath)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to read terraform state: %w", err)
	}

	var state TerraformState
	if err := json.Unmarshal(output, &state); err != nil {
		return nil, fmt.Errorf("failed to parse terraform state: %w", err)
	}

	return &state, nil
}

// ListTerraformWorkspaces lists all workspaces
func ListTerraformWorkspaces(workDir string) ([]TerraformWorkspace, error) {
	cmd := exec.Command("terraform", "workspace", "list")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to list workspaces: %w", err)
	}

	var workspaces []TerraformWorkspace
	lines := string(output)

	for _, line := range strings.Split(lines, "\n") {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		workspace := TerraformWorkspace{}
		if strings.HasPrefix(line, "*") {
			workspace.Current = true
			workspace.Name = strings.TrimSpace(line[1:])
		} else {
			workspace.Name = line
		}

		workspaces = append(workspaces, workspace)
	}

	return workspaces, nil
}

// GetTerraformOutputs gets outputs from current state
func GetTerraformOutputs(workDir string) (map[string]interface{}, error) {
	cmd := exec.Command("terraform", "output", "-json")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get terraform outputs: %w", err)
	}

	var outputs map[string]interface{}
	if err := json.Unmarshal(output, &outputs); err != nil {
		return nil, fmt.Errorf("failed to parse terraform outputs: %w", err)
	}

	return outputs, nil
}

// ValidateTerraformConfig validates terraform configuration
func ValidateTerraformConfig(workDir string) error {
	cmd := exec.Command("terraform", "validate", "-json")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("terraform validation failed: %w", err)
	}

	var result struct {
		Valid        bool `json:"valid"`
		ErrorCount   int  `json:"error_count"`
		WarningCount int  `json:"warning_count"`
		Diagnostics  []struct {
			Severity string `json:"severity"`
			Summary  string `json:"summary"`
			Detail   string `json:"detail"`
		} `json:"diagnostics"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return fmt.Errorf("failed to parse validation result: %w", err)
	}

	if !result.Valid {
		return fmt.Errorf("terraform configuration is invalid: %d errors", result.ErrorCount)
	}

	return nil
}

// GetTerraformPlan gets the plan output
func GetTerraformPlan(workDir string) (string, error) {
	cmd := exec.Command("terraform", "plan", "-no-color")
	cmd.Dir = workDir

	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get terraform plan: %w", err)
	}

	return string(output), nil
}
