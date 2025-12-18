package models

import "time"

type ArgoApplication struct {
	ID             string    `json:"id"`
	UserID         string    `json:"user_id"`
	Path           string    `json:"path"`
	Name           string    `json:"name"`
	RepoURL        string    `json:"repo_url"`
	TargetRevision string    `json:"target_revision"`
	Destination    string    `json:"destination"` // Server URL
	Content        string    `json:"content"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// ArgoAppDetail represents the runtime state of an application
type ArgoAppDetail struct {
	Name      string           `json:"name"`
	Project   string           `json:"project"`
	Source    ArgoSource       `json:"source"`
	Dest      ArgoDestination  `json:"destination"`
	Sync      ArgoSyncStatus   `json:"sync"`
	Health    ArgoHealthStatus `json:"health"`
	Operation *ArgoOperation   `json:"operation,omitempty"`
}

type ArgoSource struct {
	RepoURL        string `json:"repoURL"`
	Path           string `json:"path"`
	TargetRevision string `json:"targetRevision"`
}

type ArgoDestination struct {
	Server    string `json:"server"`
	Namespace string `json:"namespace"`
}

type ArgoSyncStatus struct {
	Status   string `json:"status"`   // Synced, OutOfSync
	Revision string `json:"revision"` // Git revision
}

type ArgoHealthStatus struct {
	Status  string `json:"status"`  // Healthy, Degraded, Progressing, Missing, Suspended, Unknown
	Message string `json:"message"` // Detailed message
}

type ArgoOperation struct {
	Sync *ArgoSyncOperation `json:"sync"`
}

type ArgoSyncOperation struct {
	Revision string `json:"revision"`
	Status   string `json:"status"`
}
