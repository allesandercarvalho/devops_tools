package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/devopstools/agent/internal/checker"
	"github.com/devopstools/agent/internal/collector"
	"github.com/devopstools/agent/internal/sync"
	"github.com/devopstools/agent/internal/watcher"
)

const (
	AgentVersion = "1.0.0"
)

func main() {
	log.Printf("🤖 DevOps Tools Agent v%s starting...", AgentVersion)

	// Get device info
	deviceID := getDeviceID()
	deviceName, _ := os.Hostname()
	osType := getOSType()

	log.Printf("Device: %s (%s)", deviceName, deviceID)
	log.Printf("OS: %s", osType)

	// Check CLI tools
	cliChecker := checker.NewCLIChecker()
	cliChecker.CheckAll()
	log.Println(cliChecker.GetStatus())

	// Initialize Collector
	dataCollector := collector.NewCollector()

	// Initialize Sync Components
	syncTracker := sync.NewSyncTracker()
	conflictResolver := sync.NewConflictResolver(sync.AskUser) // Default strategy

	// Start Sync Engine
	engine := sync.NewEngine()
	go engine.Start()

	// Start File Watcher
	cwd, _ := os.Getwd()
	w, err := watcher.New([]string{cwd}, engine.OnFileChanged)
	if err != nil {
		log.Fatalf("❌ Failed to create watcher: %v", err)
	}
	if err := w.Start(); err != nil {
		log.Fatalf("❌ Failed to start watcher: %v", err)
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	log.Println("✅ Agent is running. Press Ctrl+C to stop.")

	// Main loop
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	// Initial collection
	go collectAndSync(dataCollector, syncTracker, conflictResolver)

	for {
		select {
		case <-ticker.C:
			// Periodic sync check
			log.Println("🔄 Starting periodic collection...")
			go collectAndSync(dataCollector, syncTracker, conflictResolver)
		case <-sigChan:
			log.Println("🛑 Shutting down agent...")
			return
		}
	}
}

func collectAndSync(c *collector.Collector, st *sync.SyncTracker, cr *sync.ConflictResolver) {
	data, err := c.Collect()
	if err != nil {
		log.Printf("❌ Collection failed: %v", err)
		return
	}

	// Log summary of collected data
	log.Printf("📊 Collected Data Summary:")
	log.Printf("  - AWS Stacks: %d", len(data.AWS.Stacks))
	log.Printf("  - AWS ECS Clusters: %d", len(data.AWS.ECS))
	log.Printf("  - K8s Contexts: %d", len(data.Kubernetes.Contexts))
	log.Printf("  - Terraform Workspaces: %d", len(data.Terraform.Workspaces))

	// Send data to backend
	sendToBackend(data)
}

func sendToBackend(data *collector.CollectedData) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("❌ Failed to marshal data: %v", err)
		return
	}

	// TODO: Get backend URL from config
	backendURL := "http://localhost:3002/api/sync/agent-data"

	resp, err := http.Post(backendURL, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("❌ Failed to send data to backend: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		log.Printf("✅ Data synced to backend successfully")
	} else {
		log.Printf("⚠️ Backend returned status: %s", resp.Status)
	}
}

func getDeviceID() string {
	// TODO: Generate or retrieve persistent device ID
	return fmt.Sprintf("dev-%d", time.Now().Unix())
}

func getOSType() string {
	switch os.Getenv("GOOS") {
	case "darwin":
		return "macOS"
	case "linux":
		return "Linux"
	case "windows":
		return "Windows"
	default:
		return "Unknown"
	}
}
