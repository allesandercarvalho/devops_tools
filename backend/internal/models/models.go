package models

import "time"

// ToolConfig represents a CLI tool configuration
type ToolConfig struct {
	ID          string                 `json:"id"`
	UserID      string                 `json:"user_id"`
	ToolType    string                 `json:"tool_type"` // "aws", "kubectl", "terraform", etc.
	ProfileName string                 `json:"profile_name"`
	ConfigData  map[string]interface{} `json:"config_data"`
	Tags        []string               `json:"tags"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
}

// Secret represents encrypted secret data
type Secret struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	ToolConfigID  string    `json:"tool_config_id"`
	EncryptedData string    `json:"encrypted_data"`
	EncryptionIV  string    `json:"encryption_iv"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// SyncEvent represents a synchronization event
type SyncEvent struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	ToolConfigID string    `json:"tool_config_id"`
	EventType    string    `json:"event_type"` // "create", "update", "delete"
	Source       string    `json:"source"`     // "app", "agent"
	DeviceID     string    `json:"device_id"`
	Synced       bool      `json:"synced"`
	CreatedAt    time.Time `json:"created_at"`
}

// CommandHistory represents a command execution record
type CommandHistory struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Command     string    `json:"command"`
	FullCommand string    `json:"full_command"`
	Status      string    `json:"status"` // success, failed
	Output      string    `json:"output,omitempty"`
	Error       string    `json:"error,omitempty"`
	ExitCode    int       `json:"exit_code"`
	Duration    int64     `json:"duration_ms"` // milliseconds
	Timestamp   time.Time `json:"timestamp"`
	Tags        []string  `json:"tags,omitempty"` // e.g., ["aws", "ec2"]
	ToolType    string    `json:"tool_type,omitempty"`
	ProfileName string    `json:"profile_name,omitempty"`
	DeviceID    string    `json:"device_id,omitempty"`
}

// Device represents a registered device
type Device struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	DeviceName   string    `json:"device_name"`
	DeviceID     string    `json:"device_id"`
	OSType       string    `json:"os_type"`
	LastSync     time.Time `json:"last_sync"`
	AgentVersion string    `json:"agent_version"`
	CreatedAt    time.Time `json:"created_at"`
}
