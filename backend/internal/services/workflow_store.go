package services

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

type WorkflowStore struct {
	dataDir string
	mu      sync.RWMutex
}

func NewWorkflowStore(dataDir string) (*WorkflowStore, error) {
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create data directory: %w", err)
	}
	return &WorkflowStore{dataDir: dataDir}, nil
}

func (s *WorkflowStore) List() ([]models.Workflow, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	entries, err := os.ReadDir(s.dataDir)
	if err != nil {
		return nil, err
	}

	var workflows []models.Workflow
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}

		data, err := os.ReadFile(filepath.Join(s.dataDir, entry.Name()))
		if err != nil {
			continue // Skip unreadable files
		}

		var wf models.Workflow
		if err := json.Unmarshal(data, &wf); err == nil {
			workflows = append(workflows, wf)
		}
	}

	return workflows, nil
}

func (s *WorkflowStore) Get(id string) (*models.Workflow, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	path := filepath.Join(s.dataDir, id+".json")
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("workflow not found")
		}
		return nil, err
	}

	var wf models.Workflow
	if err := json.Unmarshal(data, &wf); err != nil {
		return nil, err
	}

	return &wf, nil
}

func (s *WorkflowStore) Save(wf models.Workflow) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if wf.ID == "" {
		wf.ID = uuid.New().String()
	}

	data, err := json.MarshalIndent(wf, "", "  ")
	if err != nil {
		return err
	}

	path := filepath.Join(s.dataDir, wf.ID+".json")
	return os.WriteFile(path, data, 0644)
}

func (s *WorkflowStore) Delete(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	path := filepath.Join(s.dataDir, id+".json")
	return os.Remove(path)
}
