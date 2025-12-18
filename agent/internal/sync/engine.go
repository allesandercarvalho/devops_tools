package sync

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"path/filepath"
	"time"

	"github.com/devopstools/agent/internal/crypto"
	"github.com/devopstools/agent/internal/parsers/argocd"
	"github.com/devopstools/agent/internal/parsers/aws"
	"github.com/devopstools/agent/internal/parsers/terraform"
	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/websocket"
)

const (
	API_URL = "http://localhost:3002/api"
)

type Engine struct {
	client *http.Client
}

func NewEngine() *Engine {
	return &Engine{
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

func (e *Engine) Start() {
	log.Println("🚀 Sync Engine started")

	// Initial sync
	e.syncDown()

	// Start WebSocket listener
	go e.listenWS()

	// Keep polling as backup (every 30s instead of 5s)
	ticker := time.NewTicker(30 * time.Second)
	for range ticker.C {
		e.syncDown()
	}
}

func (e *Engine) OnFileChanged(path string, op fsnotify.Op) {
	log.Printf("📝 File changed: %s [%s]", path, op)

	// Check file type
	if filepath.Ext(path) == ".tf" {
		e.handleTerraformFile(path)
		return
	}

	if filepath.Ext(path) == ".yaml" || filepath.Ext(path) == ".yml" {
		e.handleArgoFile(path)
		return
	}
}

func (e *Engine) handleArgoFile(path string) {
	log.Printf("Processing YAML file: %s", path)

	info, err := argocd.Parse(path)
	if err != nil {
		log.Printf("❌ Failed to parse YAML file: %v", err)
		return
	}
	if info == nil {
		// Not an ArgoCD app
		return
	}

	// Create payload
	payload := map[string]interface{}{
		"path":            path,
		"name":            info.Name,
		"repo_url":        info.RepoURL,
		"target_revision": info.TargetRevision,
		"destination":     info.Destination,
		"content":         info.Content,
	}

	jsonPayload, _ := json.Marshal(payload)
	resp, err := e.client.Post(API_URL+"/argocd/apps", "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		log.Printf("❌ Failed to sync ArgoCD app: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 201 {
		log.Printf("❌ Backend returned error: %d", resp.StatusCode)
	} else {
		log.Printf("✅ Synced ArgoCD app: %s", info.Name)
	}
}

func (e *Engine) handleTerraformFile(path string) {
	log.Printf("Processing Terraform file: %s", path)

	info, err := terraform.Parse(path)
	if err != nil {
		log.Printf("❌ Failed to parse Terraform file: %v", err)
		return
	}

	// Create payload
	payload := map[string]interface{}{
		"path":      path,
		"content":   info.Content,
		"resources": info.Resources,
		"variables": info.Variables,
	}

	jsonPayload, _ := json.Marshal(payload)
	resp, err := e.client.Post(API_URL+"/terraform/configs", "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		log.Printf("❌ Failed to sync Terraform config: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 201 {
		log.Printf("❌ Backend returned error: %d", resp.StatusCode)
	} else {
		log.Printf("✅ Synced Terraform config: %s", path)
	}
}

func (e *Engine) listenWS() {
	for {
		log.Println("🔌 Connecting to WebSocket...")
		c, _, err := websocket.DefaultDialer.Dial("ws://localhost:3002/ws", nil)
		if err != nil {
			log.Printf("❌ WebSocket connection failed: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}
		log.Println("✅ WebSocket connected")

		for {
			_, message, err := c.ReadMessage()
			if err != nil {
				log.Println("❌ WebSocket read error:", err)
				break
			}
			log.Printf("📩 Received WS event: %s", message)

			// Trigger sync
			e.syncDown()
		}
		c.Close()
		time.Sleep(2 * time.Second)
	}
}

func (e *Engine) syncDown() {
	// 1. Get pending events
	events, err := e.getPendingEvents()
	if err != nil {
		log.Printf("❌ Failed to get events: %v", err)
		return
	}

	if len(events) == 0 {
		return
	}

	log.Printf("📥 Received %d sync events", len(events))

	for _, event := range events {
		log.Printf("Processing event: %s %s", event.EventType, event.ToolConfigID)

		// Get full config
		config, err := e.getConfig(event.ToolConfigID)
		if err != nil {
			log.Printf("❌ Failed to get config %s: %v", event.ToolConfigID, err)
			continue
		}

		// Apply config locally
		if err := e.applyConfig(config); err != nil {
			log.Printf("❌ Failed to apply config: %v", err)
			continue
		}

		// Acknowledge event
		if err := e.ackEvent(event.ID); err != nil {
			log.Printf("❌ Failed to ack event: %v", err)
		}
	}
}

// API Client methods

func (e *Engine) getPendingEvents() ([]SyncEvent, error) {
	resp, err := e.client.Get(API_URL + "/sync/events")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var events []SyncEvent
	if err := json.NewDecoder(resp.Body).Decode(&events); err != nil {
		return nil, err
	}
	return events, nil
}

func (e *Engine) getConfig(id string) (ToolConfig, error) {
	resp, err := e.client.Get(API_URL + "/configs/" + id)
	if err != nil {
		return ToolConfig{}, err
	}
	defer resp.Body.Close()

	var config ToolConfig
	if err := json.NewDecoder(resp.Body).Decode(&config); err != nil {
		return ToolConfig{}, err
	}
	return config, nil
}

func (e *Engine) ackEvent(id string) error {
	payload := map[string]string{"event_id": id}
	data, _ := json.Marshal(payload)

	resp, err := e.client.Post(API_URL+"/sync/ack", "application/json", bytes.NewBuffer(data))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	return nil
}

// Logic methods

func (e *Engine) applyConfig(config ToolConfig) error {
	if config.ToolType == "aws" {
		log.Printf("☁️  Applying AWS Config: %s", config.ProfileName)

		// Read current AWS config
		awsConfig, err := aws.ParseAWSConfig()
		if err != nil {
			// If file doesn't exist, start fresh
			awsConfig = &aws.AWSConfig{Profiles: make(map[string]aws.Profile)}
		}

		// Update profile
		profile := aws.Profile{
			Name: config.ProfileName,
		}

		if region, ok := config.ConfigData["region"].(string); ok {
			profile.Region = region
		}

		// Handle credentials if present
		if config.Secrets != nil {
			// In a real app, we would prompt the user for their master password
			// For this MVP/Dev mode, we'll use a hardcoded dev password
			// TODO: Implement secure password prompt/storage
			masterPassword := "dev-password"
			salt := "dev-salt" // Should match backend
			key := crypto.DeriveKey(masterPassword, salt)

			if accessKeyEnc, ok := config.Secrets["aws_access_key_id"]; ok {
				decrypted, err := crypto.Decrypt(accessKeyEnc, key)
				if err == nil {
					profile.AccessKeyID = string(decrypted)
				} else {
					log.Printf("⚠️ Failed to decrypt access key: %v", err)
				}
			}

			if secretKeyEnc, ok := config.Secrets["aws_secret_access_key"]; ok {
				decrypted, err := crypto.Decrypt(secretKeyEnc, key)
				if err == nil {
					profile.SecretAccessKey = string(decrypted)
				} else {
					log.Printf("⚠️ Failed to decrypt secret key: %v", err)
				}
			}
		}

		awsConfig.Profiles[config.ProfileName] = profile

		// Write back
		if err := aws.WriteAWSConfig(awsConfig); err != nil {
			return err
		}

		log.Printf("✅ AWS Config applied successfully")
	}
	return nil
}

// Models (mirrored from backend)
type SyncEvent struct {
	ID           string `json:"id"`
	EventType    string `json:"event_type"`
	ToolConfigID string `json:"tool_config_id"`
}

type ToolConfig struct {
	ID          string                 `json:"id"`
	ToolType    string                 `json:"tool_type"`
	ProfileName string                 `json:"profile_name"`
	ConfigData  map[string]interface{} `json:"config_data"`
	Secrets     map[string]string      `json:"secrets,omitempty"`
}
