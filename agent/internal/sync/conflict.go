package sync

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"time"
)

// ConflictResolution strategies
type ConflictResolution string

const (
	// KeepLocal keeps the local version
	KeepLocal ConflictResolution = "keep_local"
	// KeepRemote keeps the remote version
	KeepRemote ConflictResolution = "keep_remote"
	// MergeChanges attempts to merge both versions
	MergeChanges ConflictResolution = "merge"
	// AskUser prompts user for resolution
	AskUser ConflictResolution = "ask"
)

// SyncConflict represents a synchronization conflict
type SyncConflict struct {
	ID            string             `json:"id"`
	ResourceID    string             `json:"resource_id"`
	ResourceType  string             `json:"resource_type"`
	LocalVersion  interface{}        `json:"local_version"`
	RemoteVersion interface{}        `json:"remote_version"`
	LocalHash     string             `json:"local_hash"`
	RemoteHash    string             `json:"remote_hash"`
	DetectedAt    time.Time          `json:"detected_at"`
	Resolution    ConflictResolution `json:"resolution,omitempty"`
	ResolvedAt    *time.Time         `json:"resolved_at,omitempty"`
}

// SyncMetadata tracks sync state
type SyncMetadata struct {
	ResourceID   string    `json:"resource_id"`
	ResourceType string    `json:"resource_type"`
	LastSyncedAt time.Time `json:"last_synced_at"`
	Hash         string    `json:"hash"`
	Version      int       `json:"version"`
}

// ConflictResolver handles sync conflicts
type ConflictResolver struct {
	strategy  ConflictResolution
	conflicts []SyncConflict
}

// NewConflictResolver creates a new conflict resolver
func NewConflictResolver(strategy ConflictResolution) *ConflictResolver {
	return &ConflictResolver{
		strategy:  strategy,
		conflicts: make([]SyncConflict, 0),
	}
}

// DetectConflict checks if there's a conflict between local and remote
func (cr *ConflictResolver) DetectConflict(resourceID, resourceType string, local, remote interface{}) (*SyncConflict, error) {
	localHash, err := hashObject(local)
	if err != nil {
		return nil, fmt.Errorf("failed to hash local object: %w", err)
	}

	remoteHash, err := hashObject(remote)
	if err != nil {
		return nil, fmt.Errorf("failed to hash remote object: %w", err)
	}

	// No conflict if hashes match
	if localHash == remoteHash {
		return nil, nil
	}

	conflict := &SyncConflict{
		ID:            fmt.Sprintf("conflict-%d", time.Now().Unix()),
		ResourceID:    resourceID,
		ResourceType:  resourceType,
		LocalVersion:  local,
		RemoteVersion: remote,
		LocalHash:     localHash,
		RemoteHash:    remoteHash,
		DetectedAt:    time.Now(),
	}

	cr.conflicts = append(cr.conflicts, *conflict)
	return conflict, nil
}

// ResolveConflict resolves a conflict based on strategy
func (cr *ConflictResolver) ResolveConflict(conflict *SyncConflict) (interface{}, error) {
	switch cr.strategy {
	case KeepLocal:
		return conflict.LocalVersion, nil

	case KeepRemote:
		return conflict.RemoteVersion, nil

	case MergeChanges:
		// Attempt to merge (simplified - in real implementation would be more sophisticated)
		merged, err := mergeObjects(conflict.LocalVersion, conflict.RemoteVersion)
		if err != nil {
			return nil, fmt.Errorf("failed to merge: %w", err)
		}
		return merged, nil

	case AskUser:
		// In real implementation, would prompt user
		return nil, fmt.Errorf("user resolution required")

	default:
		return nil, fmt.Errorf("unknown resolution strategy: %s", cr.strategy)
	}
}

// GetConflicts returns all detected conflicts
func (cr *ConflictResolver) GetConflicts() []SyncConflict {
	return cr.conflicts
}

// ClearConflicts clears all conflicts
func (cr *ConflictResolver) ClearConflicts() {
	cr.conflicts = make([]SyncConflict, 0)
}

// hashObject creates a hash of an object
func hashObject(obj interface{}) (string, error) {
	data, err := json.Marshal(obj)
	if err != nil {
		return "", err
	}

	hash := sha256.Sum256(data)
	return hex.EncodeToString(hash[:]), nil
}

// mergeObjects attempts to merge two objects
func mergeObjects(local, remote interface{}) (interface{}, error) {
	// Simplified merge - in real implementation would handle different types
	localMap, ok1 := local.(map[string]interface{})
	remoteMap, ok2 := remote.(map[string]interface{})

	if !ok1 || !ok2 {
		return nil, fmt.Errorf("cannot merge non-map objects")
	}

	merged := make(map[string]interface{})

	// Copy all local values
	for k, v := range localMap {
		merged[k] = v
	}

	// Add remote values that don't exist locally
	for k, v := range remoteMap {
		if _, exists := merged[k]; !exists {
			merged[k] = v
		}
	}

	return merged, nil
}

// SyncTracker tracks sync metadata
type SyncTracker struct {
	metadata map[string]SyncMetadata
}

// NewSyncTracker creates a new sync tracker
func NewSyncTracker() *SyncTracker {
	return &SyncTracker{
		metadata: make(map[string]SyncMetadata),
	}
}

// Track records sync metadata for a resource
func (st *SyncTracker) Track(resourceID, resourceType string, data interface{}) error {
	hash, err := hashObject(data)
	if err != nil {
		return err
	}

	existing, exists := st.metadata[resourceID]
	version := 1
	if exists {
		version = existing.Version + 1
	}

	st.metadata[resourceID] = SyncMetadata{
		ResourceID:   resourceID,
		ResourceType: resourceType,
		LastSyncedAt: time.Now(),
		Hash:         hash,
		Version:      version,
	}

	return nil
}

// GetMetadata retrieves sync metadata for a resource
func (st *SyncTracker) GetMetadata(resourceID string) (SyncMetadata, bool) {
	meta, exists := st.metadata[resourceID]
	return meta, exists
}

// HasChanged checks if a resource has changed since last sync
func (st *SyncTracker) HasChanged(resourceID string, data interface{}) (bool, error) {
	meta, exists := st.GetMetadata(resourceID)
	if !exists {
		return true, nil // New resource
	}

	currentHash, err := hashObject(data)
	if err != nil {
		return false, err
	}

	return currentHash != meta.Hash, nil
}
