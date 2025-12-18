package models

import "time"

// Workflow represents a complete workflow with steps and variables
type Workflow struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	Category    string     `json:"category"`
	Variables   []Variable `json:"variables"`
	Steps       []Step     `json:"steps"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// Variable represents a workflow variable (global or local)
type Variable struct {
	Name         string   `json:"name"`
	Description  string   `json:"description"`
	Type         string   `json:"type"` // string, number, select, boolean
	DefaultValue string   `json:"default_value,omitempty"`
	Options      []string `json:"options,omitempty"` // For select type
	IsGlobal     bool     `json:"is_global"`         // Global or template-specific
	Required     bool     `json:"required"`
}

// Step represents a single step in a workflow
type Step struct {
	ID         string            `json:"id"`
	Name       string            `json:"name"`
	Type       string            `json:"type"` // command, workflow_ref, conditional
	Order      int               `json:"order"`
	Content    string            `json:"content"`              // Command or workflow_id
	Variables  map[string]string `json:"variables,omitempty"`  // Variable mappings
	Conditions []Condition       `json:"conditions,omitempty"` // Conditional logic
	OnSuccess  *StepAction       `json:"on_success,omitempty"`
	OnFailure  *StepAction       `json:"on_failure,omitempty"`
}

// Condition represents a conditional check on step output
type Condition struct {
	Type     string     `json:"type"`  // contains, equals, starts_with, ends_with, regex, exit_code
	Value    string     `json:"value"` // Value to compare
	Operator string     `json:"operator,omitempty"` // AND, OR (for multiple conditions)
	Action   StepAction `json:"action"`
}

// StepAction defines what to do based on condition result
type StepAction struct {
	Type   string `json:"type"`   // continue, stop, jump_to, execute_step
	Target string `json:"target"` // Step ID or workflow ID
}

// WorkflowExecution tracks the execution state
type WorkflowExecution struct {
	ID         string            `json:"id"`
	WorkflowID string            `json:"workflow_id"`
	Status     string            `json:"status"` // pending, running, completed, failed, cancelled
	Variables  map[string]string `json:"variables"`
	Logs       []ExecutionLog    `json:"logs"`
	StartTime  string            `json:"start_time"`
	EndTime    string            `json:"end_time,omitempty"`
}

// ExecutionLog represents a single log entry during execution
type ExecutionLog struct {
	Timestamp string `json:"timestamp"`
	StepID    string `json:"step_id,omitempty"`
	Level     string `json:"level"` // info, warning, error
	Message   string `json:"message"`
	Output    string `json:"output,omitempty"`
}

// GlobalVariable represents a reusable global variable
type GlobalVariable struct {
	Name        string    `json:"name"`
	Value       string    `json:"value"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}
