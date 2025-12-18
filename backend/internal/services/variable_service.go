package services

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/devopstools/backend/internal/models"
)

type VariableService struct {
	dataDir string
	mu      sync.RWMutex
	cache   map[string]models.GlobalVariable
}

func NewVariableService(dataDir string) (*VariableService, error) {
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create data directory: %w", err)
	}

	vs := &VariableService{
		dataDir: dataDir,
		cache:   make(map[string]models.GlobalVariable),
	}

	// Load existing variables into cache
	if err := vs.loadCache(); err != nil {
		return nil, err
	}

	return vs, nil
}

func (vs *VariableService) loadCache() error {
	path := filepath.Join(vs.dataDir, "global_variables.json")

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // No variables yet, that's ok
		}
		return err
	}

	var variables []models.GlobalVariable
	if err := json.Unmarshal(data, &variables); err != nil {
		return err
	}

	for _, v := range variables {
		vs.cache[v.Name] = v
	}

	return nil
}

func (vs *VariableService) saveCache() error {
	vs.mu.RLock()
	defer vs.mu.RUnlock()

	variables := make([]models.GlobalVariable, 0, len(vs.cache))
	for _, v := range vs.cache {
		variables = append(variables, v)
	}

	data, err := json.MarshalIndent(variables, "", "  ")
	if err != nil {
		return err
	}

	path := filepath.Join(vs.dataDir, "global_variables.json")
	return os.WriteFile(path, data, 0644)
}

func (vs *VariableService) List() []models.GlobalVariable {
	vs.mu.RLock()
	defer vs.mu.RUnlock()

	variables := make([]models.GlobalVariable, 0, len(vs.cache))
	for _, v := range vs.cache {
		variables = append(variables, v)
	}

	return variables
}

func (vs *VariableService) Get(name string) (*models.GlobalVariable, error) {
	vs.mu.RLock()
	defer vs.mu.RUnlock()

	v, ok := vs.cache[name]
	if !ok {
		return nil, fmt.Errorf("variable not found: %s", name)
	}

	return &v, nil
}

func (vs *VariableService) Set(variable models.GlobalVariable) error {
	vs.mu.Lock()
	defer vs.mu.Unlock()

	now := time.Now()
	if variable.CreatedAt.IsZero() {
		variable.CreatedAt = now
	}
	variable.UpdatedAt = now

	vs.cache[variable.Name] = variable

	return vs.saveCache()
}

func (vs *VariableService) Delete(name string) error {
	vs.mu.Lock()
	defer vs.mu.Unlock()

	if _, ok := vs.cache[name]; !ok {
		return fmt.Errorf("variable not found: %s", name)
	}

	delete(vs.cache, name)

	return vs.saveCache()
}

func (vs *VariableService) GetAll() map[string]string {
	vs.mu.RLock()
	defer vs.mu.RUnlock()

	result := make(map[string]string)
	for name, v := range vs.cache {
		result[name] = v.Value
	}

	return result
}
