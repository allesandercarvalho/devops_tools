package store

import (
	"errors"
	"sync"
	"time"

	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

var (
	ErrNotFound = errors.New("record not found")
)

type MemoryStore struct {
	configs          map[string]models.ToolConfig
	secrets          map[string]models.Secret
	terraformConfigs map[string]models.TerraformConfig
	argoApps         map[string]models.ArgoApplication
	syncEvents       []models.SyncEvent
	cmdHistory       []models.CommandHistory
	mu               sync.RWMutex
	OnEvent          func(models.SyncEvent)
}

func NewMemoryStore() *MemoryStore {
	return &MemoryStore{
		configs:          make(map[string]models.ToolConfig),
		secrets:          make(map[string]models.Secret),
		terraformConfigs: make(map[string]models.TerraformConfig),
		argoApps:         make(map[string]models.ArgoApplication),
		syncEvents:       make([]models.SyncEvent, 0),
		cmdHistory:       make([]models.CommandHistory, 0),
	}
}

// Tool Configs
func (s *MemoryStore) ListConfigs(userID string) ([]models.ToolConfig, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []models.ToolConfig
	for _, c := range s.configs {
		if c.UserID == userID {
			result = append(result, c)
		}
	}
	return result, nil
}

func (s *MemoryStore) GetConfig(id string) (models.ToolConfig, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if c, ok := s.configs[id]; ok {
		return c, nil
	}
	return models.ToolConfig{}, ErrNotFound
}

func (s *MemoryStore) CreateConfig(config models.ToolConfig) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if config.ID == "" {
		config.ID = uuid.New().String()
	}
	config.CreatedAt = time.Now()
	config.UpdatedAt = time.Now()

	s.configs[config.ID] = config

	// Create sync event
	s.createSyncEvent(config.UserID, config.ID, "create", "app")

	return nil
}

func (s *MemoryStore) UpdateConfig(config models.ToolConfig) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.configs[config.ID]; !ok {
		return ErrNotFound
	}

	config.UpdatedAt = time.Now()
	s.configs[config.ID] = config

	// Create sync event
	s.createSyncEvent(config.UserID, config.ID, "update", "app")

	return nil
}

func (s *MemoryStore) DeleteConfig(id string, userID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.configs[id]; !ok {
		return ErrNotFound
	}

	delete(s.configs, id)

	// Create sync event
	s.createSyncEvent(userID, id, "delete", "app")

	return nil
}

// Terraform Configs
func (s *MemoryStore) ListTerraformConfigs(userID string) ([]models.TerraformConfig, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []models.TerraformConfig
	for _, c := range s.terraformConfigs {
		if c.UserID == userID {
			result = append(result, c)
		}
	}
	return result, nil
}

func (s *MemoryStore) GetTerraformConfig(id string) (models.TerraformConfig, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if c, ok := s.terraformConfigs[id]; ok {
		return c, nil
	}
	return models.TerraformConfig{}, ErrNotFound
}

func (s *MemoryStore) CreateTerraformConfig(config models.TerraformConfig) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if config.ID == "" {
		config.ID = uuid.New().String()
	}
	config.CreatedAt = time.Now()
	config.UpdatedAt = time.Now()

	s.terraformConfigs[config.ID] = config

	// Create sync event
	s.createSyncEvent(config.UserID, config.ID, "create", "terraform")

	return nil
}

func (s *MemoryStore) UpdateTerraformConfig(config models.TerraformConfig) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.terraformConfigs[config.ID]; !ok {
		return ErrNotFound
	}

	config.UpdatedAt = time.Now()
	s.terraformConfigs[config.ID] = config

	// Create sync event
	s.createSyncEvent(config.UserID, config.ID, "update", "terraform")

	return nil
}

// ArgoCD Apps
func (s *MemoryStore) ListArgoApps(userID string) ([]models.ArgoApplication, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []models.ArgoApplication
	for _, app := range s.argoApps {
		if app.UserID == userID {
			result = append(result, app)
		}
	}
	return result, nil
}

func (s *MemoryStore) CreateArgoApp(app models.ArgoApplication) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if app.ID == "" {
		app.ID = uuid.New().String()
	}
	app.CreatedAt = time.Now()
	app.UpdatedAt = time.Now()

	s.argoApps[app.ID] = app

	// Create sync event
	s.createSyncEvent(app.UserID, app.ID, "create", "argocd")

	return nil
}

func (s *MemoryStore) UpdateArgoApp(app models.ArgoApplication) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.argoApps[app.ID]; !ok {
		return ErrNotFound
	}

	app.UpdatedAt = time.Now()
	s.argoApps[app.ID] = app

	// Create sync event
	s.createSyncEvent(app.UserID, app.ID, "update", "argocd")

	return nil
}

func (s *MemoryStore) CreateSecret(secret models.Secret) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if secret.ID == "" {
		secret.ID = uuid.New().String()
	}
	secret.CreatedAt = time.Now()
	secret.UpdatedAt = time.Now()

	s.secrets[secret.ToolConfigID] = secret

	return nil
}

func (s *MemoryStore) GetSecret(configID string) (models.Secret, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if s, ok := s.secrets[configID]; ok {
		return s, nil
	}
	return models.Secret{}, ErrNotFound
}

// Sync Events
func (s *MemoryStore) createSyncEvent(userID, configID, eventType, source string) {
	event := models.SyncEvent{
		ID:           uuid.New().String(),
		UserID:       userID,
		ToolConfigID: configID,
		EventType:    eventType,
		Source:       source,
		Synced:       false,
		CreatedAt:    time.Now(),
	}
	s.syncEvents = append(s.syncEvents, event)

	if s.OnEvent != nil {
		go s.OnEvent(event)
	}
}

func (s *MemoryStore) GetPendingSyncEvents(userID string) ([]models.SyncEvent, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []models.SyncEvent
	for _, e := range s.syncEvents {
		if e.UserID == userID && !e.Synced {
			result = append(result, e)
		}
	}
	return result, nil
}

func (s *MemoryStore) AcknowledgeSyncEvent(eventID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i, e := range s.syncEvents {
		if e.ID == eventID {
			s.syncEvents[i].Synced = true
			return nil
		}
	}
	return ErrNotFound
}

// Command History
func (s *MemoryStore) SaveCommandHistory(history models.CommandHistory) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if history.ID == "" {
		history.ID = uuid.New().String()
	}
	if history.Timestamp.IsZero() {
		history.Timestamp = time.Now()
	}

	s.cmdHistory = append(s.cmdHistory, history)
	return nil
}

func (s *MemoryStore) GetCommandHistory(userID string, limit int) ([]models.CommandHistory, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var result []models.CommandHistory
	count := 0

	// Return most recent first
	for i := len(s.cmdHistory) - 1; i >= 0 && (limit == 0 || count < limit); i-- {
		if s.cmdHistory[i].UserID == userID {
			result = append(result, s.cmdHistory[i])
			count++
		}
	}

	return result, nil
}

func (s *MemoryStore) GetCommandHistoryByID(id string) (models.CommandHistory, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, h := range s.cmdHistory {
		if h.ID == id {
			return h, nil
		}
	}
	return models.CommandHistory{}, ErrNotFound
}
