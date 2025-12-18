package models

import "time"

// CommandQueue represents a queue of commands to execute
type CommandQueue struct {
	ID          string     `json:"id"`
	UserID      string     `json:"user_id"`
	Name        string     `json:"name"`
	Commands    []string   `json:"commands"` // Command execution IDs
	Status      string     `json:"status"`   // pending, running, completed, failed
	CurrentStep int        `json:"current_step"`
	CreatedAt   time.Time  `json:"created_at"`
	StartedAt   *time.Time `json:"started_at,omitempty"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

// CommandTimeout represents timeout configuration
type CommandTimeout struct {
	Duration time.Duration `json:"duration"`
	Action   string        `json:"action"` // kill, continue
}

// CommandRetry represents retry configuration
type CommandRetry struct {
	MaxAttempts int           `json:"max_attempts"`
	Delay       time.Duration `json:"delay"`
	Backoff     float64       `json:"backoff"` // exponential backoff multiplier
}

// CommandProgress represents execution progress
type CommandProgress struct {
	ExecutionID string    `json:"execution_id"`
	Step        string    `json:"step"`
	Percentage  float64   `json:"percentage"`
	Message     string    `json:"message"`
	Timestamp   time.Time `json:"timestamp"`
}
