package models

import "time"

type TerraformConfig struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Path      string    `json:"path"`
	Content   string    `json:"content"`
	Resources []string  `json:"resources"` // List of resource names found
	Variables []string  `json:"variables"` // List of variable names found
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// TerraformExecution represents a terraform command execution
type TerraformExecution struct {
	ID          string     `json:"id"`
	Command     string     `json:"command"` // init, plan, apply, destroy, show
	WorkDir     string     `json:"work_dir"`
	Args        []string   `json:"args"`
	Status      string     `json:"status"` // running, completed, failed
	Output      string     `json:"output"`
	Error       string     `json:"error,omitempty"`
	StartedAt   time.Time  `json:"started_at"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
	DurationMs  int64      `json:"duration_ms"`
}

// TerraformState represents parsed terraform state
type TerraformState struct {
	FormatVersion    string           `json:"format_version"`
	TerraformVersion string           `json:"terraform_version"`
	Values           *TerraformValues `json:"values,omitempty"`
}

type TerraformValues struct {
	RootModule *TerraformModule `json:"root_module,omitempty"`
}

type TerraformModule struct {
	Resources    []*TerraformResource `json:"resources,omitempty"`
	ChildModules []*TerraformModule   `json:"child_modules,omitempty"`
}

type TerraformResource struct {
	Address         string                 `json:"address"`
	Mode            string                 `json:"mode"`
	Type            string                 `json:"type"`
	Name            string                 `json:"name"`
	ProviderName    string                 `json:"provider_name"`
	SchemaVersion   int                    `json:"schema_version"`
	AttributeValues map[string]interface{} `json:"values,omitempty"`
}
