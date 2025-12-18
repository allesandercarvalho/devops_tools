package models

import "time"

// CommandExecution represents a command execution request/response
type CommandExecution struct {
	ID        string     `json:"id"`
	UserID    string     `json:"user_id"`
	Command   string     `json:"command"`
	Args      []string   `json:"args,omitempty"`
	WorkDir   string     `json:"work_dir,omitempty"`
	Status    string     `json:"status"` // pending, running, success, failed
	Output    string     `json:"output,omitempty"`
	Error     string     `json:"error,omitempty"`
	ExitCode  int        `json:"exit_code"`
	StartedAt time.Time  `json:"started_at"`
	EndedAt   *time.Time `json:"ended_at,omitempty"`
	Duration  int64      `json:"duration_ms,omitempty"` // milliseconds
}
