package main

import (
	"encoding/json"
	"log"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/devopstools/backend/internal/logger"
	"github.com/devopstools/backend/internal/metrics"
	"github.com/devopstools/backend/internal/models"
	"github.com/devopstools/backend/internal/services"
	"github.com/devopstools/backend/internal/store"
	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	fiberlogger "github.com/gofiber/fiber/v2/middleware/logger"
)

func main() {
	// Initialize logger
	logDir := os.Getenv("LOG_DIR")
	if logDir == "" {
		logDir = "./logs"
	}
	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = "info"
	}
	if err := logger.InitLogger(logDir, logLevel); err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	logger.Info("Starting DevOps Tools API")

	app := fiber.New(fiber.Config{
		AppName: "DevOps Tools API v2.0",
	})

	// Middleware
	app.Use(fiberlogger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "devops-tools-api",
			"version": "2.0",
		})
	})

	// Initialize store
	store := store.NewMemoryStore()

	// Initialize metrics
	metricsCollector := metrics.GetMetrics()

	// API routes
	api := app.Group("/api")

	// Tool configurations
	api.Get("/configs", func(c *fiber.Ctx) error {
		// Mock user ID for dev mode
		userID := "dev-user-id"
		configs, err := store.ListConfigs(userID)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(configs)
	})

	api.Post("/configs", func(c *fiber.Ctx) error {
		var config models.ToolConfig
		if err := c.BodyParser(&config); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		// Mock user ID
		config.UserID = "dev-user-id"

		if err := store.CreateConfig(config); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(config)
	})

	api.Get("/configs/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		config, err := store.GetConfig(id)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "Config not found"})
		}
		return c.JSON(config)
	})

	api.Put("/configs/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		var config models.ToolConfig
		if err := c.BodyParser(&config); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		config.ID = id
		config.UserID = "dev-user-id"

		if err := store.UpdateConfig(config); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(config)
	})

	api.Delete("/configs/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		userID := "dev-user-id"
		if err := store.DeleteConfig(id, userID); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.SendStatus(204)
	})

	// Secrets
	api.Post("/secrets", func(c *fiber.Ctx) error {
		var secret models.Secret
		if err := c.BodyParser(&secret); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		secret.UserID = "dev-user-id"
		if err := store.CreateSecret(secret); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(secret)
	})

	api.Get("/secrets/:config_id", func(c *fiber.Ctx) error {
		configID := c.Params("config_id")
		secret, err := store.GetSecret(configID)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "Secret not found"})
		}
		return c.JSON(secret)
	})

	// Sync events
	api.Get("/sync/events", func(c *fiber.Ctx) error {
		userID := "dev-user-id"
		events, err := store.GetPendingSyncEvents(userID)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(events)
	})

	api.Post("/sync/ack", func(c *fiber.Ctx) error {
		var req struct {
			EventID string `json:"event_id"`
		}
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		if err := store.AcknowledgeSyncEvent(req.EventID); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// WebSocket
	app.Use("/ws", func(c *fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			c.Locals("allowed", true)
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	})

	var clients = make(map[*websocket.Conn]bool)
	var clientsMu sync.Mutex

	app.Get("/ws", websocket.New(func(c *websocket.Conn) {
		clientsMu.Lock()
		clients[c] = true
		clientsMu.Unlock()
		log.Println("🔌 Client connected")

		defer func() {
			clientsMu.Lock()
			delete(clients, c)
			clientsMu.Unlock()
			c.Close()
			log.Println("🔌 Client disconnected")
		}()

		for {
			// Keep connection alive and read messages (if any)
			_, _, err := c.ReadMessage()
			if err != nil {
				break
			}
		}
	}))

	// Hook into store events
	store.OnEvent = func(event models.SyncEvent) {
		clientsMu.Lock()
		defer clientsMu.Unlock()

		msg, _ := json.Marshal(event)
		for client := range clients {
			if err := client.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("❌ Failed to send WS message: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}

	// Terraform Configs
	api.Get("/terraform/configs", func(c *fiber.Ctx) error {
		userID := "dev-user-id"
		configs, err := store.ListTerraformConfigs(userID)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(configs)
	})

	api.Post("/terraform/configs", func(c *fiber.Ctx) error {
		var config models.TerraformConfig
		if err := c.BodyParser(&config); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		config.UserID = "dev-user-id"
		if err := store.CreateTerraformConfig(config); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(config)
	})

	// ArgoCD Apps
	api.Get("/argocd/apps", func(c *fiber.Ctx) error {
		userID := "dev-user-id"
		apps, err := store.ListArgoApps(userID)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(apps)
	})

	api.Post("/argocd/apps", func(c *fiber.Ctx) error {
		var app models.ArgoApplication
		if err := c.BodyParser(&app); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		app.UserID = "dev-user-id"
		if err := store.CreateArgoApp(app); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(app)
	})

	// Command execution with WebSocket streaming
	cmdService := services.NewCommandService()

	// Set up output streaming via WebSocket
	cmdService.SetOutputCallback(func(execID string, output string) {
		clientsMu.Lock()
		defer clientsMu.Unlock()

		msg, _ := json.Marshal(fiber.Map{
			"type":      "command_output",
			"exec_id":   execID,
			"output":    output,
			"timestamp": time.Now(),
		})

		for client := range clients {
			if err := client.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("❌ Failed to send WS message: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	})

	api.Post("/commands/execute", func(c *fiber.Ctx) error {
		var req struct {
			Command string   `json:"command"`
			Args    []string `json:"args"`
			WorkDir string   `json:"work_dir"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		userID := "dev-user-id"
		ctx := c.Context()

		execution, err := cmdService.Execute(ctx, userID, req.Command, req.Args, req.WorkDir)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		// Save to history (async)
		go func() {
			// Wait for execution to complete
			time.Sleep(100 * time.Millisecond)
			exec, _ := cmdService.GetExecution(execution.ID)
			if exec != nil && exec.Status != "pending" && exec.Status != "running" {
				history := models.CommandHistory{
					UserID:      userID,
					Command:     exec.Command,
					FullCommand: exec.Command + " " + strings.Join(exec.Args, " "),
					Status:      exec.Status,
					Output:      exec.Output,
					Error:       exec.Error,
					ExitCode:    exec.ExitCode,
					Duration:    exec.Duration,
					Timestamp:   exec.StartedAt,
				}
				store.SaveCommandHistory(history)
			}
		}()

		return c.Status(202).JSON(execution)
	})

	api.Get("/commands/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		execution, err := cmdService.GetExecution(id)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "Execution not found"})
		}
		return c.JSON(execution)
	})

	api.Get("/commands/history", func(c *fiber.Ctx) error {
		userID := "dev-user-id"
		limit := 50 // Default limit

		history, err := store.GetCommandHistory(userID, limit)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(history)
	})

	// Initialize command queue
	cmdQueue := services.NewCommandQueue(cmdService, 5) // Max 5 concurrent
	cmdQueue.SetProgressCallback(func(progress models.CommandProgress) {
		clientsMu.Lock()
		defer clientsMu.Unlock()

		msg, _ := json.Marshal(fiber.Map{
			"type":     "command_progress",
			"progress": progress,
		})

		for client := range clients {
			if err := client.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("❌ Failed to send progress: %v", err)
			}
		}
	})

	// Queue endpoints
	api.Post("/queue", func(c *fiber.Ctx) error {
		var req struct {
			Name     string   `json:"name"`
			Commands []string `json:"commands"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		userID := "dev-user-id"
		queue, err := cmdQueue.CreateQueue(userID, req.Name, req.Commands)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.Status(201).JSON(queue)
	})

	api.Get("/queue/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		queue, err := cmdQueue.GetQueue(id)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "Queue not found"})
		}
		return c.JSON(queue)
	})

	api.Post("/queue/:id/execute", func(c *fiber.Ctx) error {
		id := c.Params("id")
		ctx := c.Context()

		go func() {
			if err := cmdQueue.ExecuteQueue(ctx, id); err != nil {
				logger.Error("Failed to execute queue", err)
			}
		}()

		return c.JSON(fiber.Map{"status": "started"})
	})

	// Metrics endpoint
	api.Get("/metrics", func(c *fiber.Ctx) error {
		snapshot := metricsCollector.GetSnapshot()
		commandMetrics := metricsCollector.GetCommandMetrics()

		return c.JSON(fiber.Map{
			"summary":  snapshot,
			"commands": commandMetrics,
		})
	})

	// Metrics reset (for testing)
	api.Post("/metrics/reset", func(c *fiber.Ctx) error {
		metricsCollector.Reset()
		return c.JSON(fiber.Map{"status": "reset"})
	})

	// Network Tools API
	networkService := services.NewNetworkToolService()
	terraformService := services.NewTerraformService()
	argoCDService := services.NewArgoCDService()
	systemService := services.NewSystemService()

	// System Dependencies
	api.Get("/system/dependencies", func(c *fiber.Ctx) error {
		deps := systemService.CheckDependencies()
		return c.JSON(deps)
	})

	// AWS Service
	awsService := services.NewAWSService()

	// AWS CLI Execute
	api.Post("/aws/execute", func(c *fiber.Ctx) error {
		var req services.CommandRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := awsService.ExecuteCommand(c.Context(), req)
		if err != nil {
			// Still return the result even if there's an error (command might have failed)
			return c.Status(500).JSON(result)
		}

		return c.JSON(result)
	})

	// AWS CLI Version
	api.Get("/aws/version", func(c *fiber.Ctx) error {
		version, err := awsService.GetAWSVersion(c.Context())
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"version": version})
	})

	// AWS List Profiles
	api.Get("/aws/profiles", func(c *fiber.Ctx) error {
		profiles, err := awsService.ListProfiles(c.Context())
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"profiles": profiles})
	})

	// AWS Browser Service
	awsBrowserService := services.NewAWSBrowserService()

	// List S3 Buckets
	api.Get("/aws/s3/buckets", func(c *fiber.Ctx) error {
		profile := c.Query("profile", "")
		buckets, err := awsBrowserService.ListS3Buckets(c.Context(), profile)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"buckets": buckets})
	})

	// List S3 Objects
	api.Get("/aws/s3/objects", func(c *fiber.Ctx) error {
		profile := c.Query("profile", "")
		bucket := c.Query("bucket")
		prefix := c.Query("prefix", "")

		if bucket == "" {
			return c.Status(400).JSON(fiber.Map{"error": "bucket parameter is required"})
		}

		objects, err := awsBrowserService.ListS3Objects(c.Context(), profile, bucket, prefix)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"objects": objects})
	})

	// List EC2 Instances
	api.Get("/aws/ec2/instances", func(c *fiber.Ctx) error {
		profile := c.Query("profile", "")
		region := c.Query("region", "us-east-1")

		instances, err := awsBrowserService.ListEC2Instances(c.Context(), profile, region)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"instances": instances})
	})

	// List RDS Instances
	api.Get("/aws/rds/instances", func(c *fiber.Ctx) error {
		profile := c.Query("profile", "")
		region := c.Query("region", "us-east-1")

		instances, err := awsBrowserService.ListRDSInstances(c.Context(), profile, region)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"instances": instances})
	})

	// List Lambda Functions
	api.Get("/aws/lambda/functions", func(c *fiber.Ctx) error {
		profile := c.Query("profile", "")
		region := c.Query("region", "us-east-1")

		functions, err := awsBrowserService.ListLambdaFunctions(c.Context(), profile, region)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"functions": functions})
	})

	// Ping
	api.Post("/network/ping", func(c *fiber.Ctx) error {
		var req struct {
			Target  string `json:"target"`
			Count   int    `json:"count"`
			Timeout int    `json:"timeout"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecutePing(req.Target, req.Count, req.Timeout)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// DNS Lookup
	api.Post("/network/dns/lookup", func(c *fiber.Ctx) error {
		var req struct {
			Target    string `json:"target"`
			QueryType string `json:"query_type"`
			Server    string `json:"server"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecuteDNSLookup(req.Target, req.QueryType, req.Server)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// Traceroute
	api.Post("/network/traceroute", func(c *fiber.Ctx) error {
		var req struct {
			Target  string `json:"target"`
			MaxHops int    `json:"max_hops"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecuteTraceroute(req.Target, req.MaxHops)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// TCP Port Check
	api.Post("/network/tcp/check", func(c *fiber.Ctx) error {
		var req struct {
			Host    string `json:"host"`
			Port    int    `json:"port"`
			Timeout int    `json:"timeout"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.CheckTCPPort(req.Host, req.Port, req.Timeout)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// HTTP Request
	api.Post("/network/http/request", func(c *fiber.Ctx) error {
		var req struct {
			Method  string            `json:"method"`
			URL     string            `json:"url"`
			Headers map[string]string `json:"headers"`
			Body    string            `json:"body"`
			Timeout int               `json:"timeout"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecuteHTTPRequest(req.Method, req.URL, req.Headers, req.Body, req.Timeout)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// Nmap Scan
	api.Post("/network/nmap/scan", func(c *fiber.Ctx) error {
		var req struct {
			Target   string                 `json:"target"`
			ScanType string                 `json:"scan_type"`
			Ports    string                 `json:"ports"` // Deprecated but kept for backward compatibility if needed, though options take precedence
			Options  map[string]interface{} `json:"options"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		// Merge legacy ports into options if options exists, or create it
		if req.Options == nil {
			req.Options = make(map[string]interface{})
		}
		if req.Ports != "" {
			req.Options["ports"] = req.Ports
		}

		result, err := networkService.ExecuteNmap(req.Target, req.ScanType, req.Options)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// Whois Lookup
	api.Post("/network/whois", func(c *fiber.Ctx) error {
		var req struct {
			Domain string `json:"domain"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecuteWhois(req.Domain)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// TLS Inspector
	api.Post("/network/tls/inspect", func(c *fiber.Ctx) error {
		var req struct {
			Host string `json:"host"`
			Port int    `json:"port"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.InspectTLS(req.Host, req.Port)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// GeoIP Lookup
	api.Post("/network/geoip", func(c *fiber.Ctx) error {
		var req struct {
			IP string `json:"ip"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.LookupGeoIP(req.IP)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// DNS Propagation
	api.Post("/network/dns/propagation", func(c *fiber.Ctx) error {
		var req struct {
			Domain string `json:"domain"`
			Type   string `json:"type"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := networkService.ExecuteDNSPropagation(req.Domain, req.Type)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// Advanced HTTP Request with curl
	curlService := services.NewCurlService()
	api.Post("/network/http/curl", func(c *fiber.Ctx) error {
		var req models.CurlRequest
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := curlService.ExecuteCurlRequest(&req)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	// Terraform Module
	api.Post("/terraform/exec", func(c *fiber.Ctx) error {
		var req struct {
			WorkDir string   `json:"work_dir"`
			Command string   `json:"command"`
			Args    []string `json:"args"`
		}

		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid request"})
		}

		result, err := terraformService.ExecuteCommand(req.WorkDir, req.Command, req.Args...)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error(), "execution": result})
		}

		return c.JSON(result)
	})

	api.Get("/terraform/state", func(c *fiber.Ctx) error {
		workDir := c.Query("work_dir")
		if workDir == "" {
			return c.Status(400).JSON(fiber.Map{"error": "work_dir is required"})
		}

		state, err := terraformService.GetState(workDir)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		return c.JSON(state)
	})

	// ArgoCD Module
	api.Get("/argocd/apps", func(c *fiber.Ctx) error {
		apps, err := argoCDService.ListApplications()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(apps)
	})

	api.Get("/argocd/apps/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		app, err := argoCDService.GetApplication(name)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(app)
	})

	api.Post("/argocd/apps/:name/sync", func(c *fiber.Ctx) error {
		name := c.Params("name")
		if err := argoCDService.SyncApplication(name); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(fiber.Map{"status": "synced"})
	})

	// Workflow Engine
	workflowStore, err := services.NewWorkflowStore("./data/workflows")
	if err != nil {
		log.Fatalf("Failed to initialize workflow store: %v", err)
	}

	variableService, err := services.NewVariableService("./data")
	if err != nil {
		log.Fatalf("Failed to initialize variable service: %v", err)
	}

	workflowExecutor := services.NewWorkflowExecutor(workflowStore, variableService)

	// Global Variables API
	api.Get("/variables", func(c *fiber.Ctx) error {
		variables := variableService.List()
		return c.JSON(variables)
	})

	api.Get("/variables/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		variable, err := variableService.Get(name)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(variable)
	})

	api.Post("/variables", func(c *fiber.Ctx) error {
		var variable models.GlobalVariable
		if err := c.BodyParser(&variable); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		if err := variableService.Set(variable); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(variable)
	})

	api.Delete("/variables/:name", func(c *fiber.Ctx) error {
		name := c.Params("name")
		if err := variableService.Delete(name); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.SendStatus(204)
	})

	// Workflows API
	api.Get("/workflows", func(c *fiber.Ctx) error {
		workflows, err := workflowStore.List()
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(workflows)
	})

	api.Get("/workflows/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		workflow, err := workflowStore.Get(id)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": err.Error()})
		}
		return c.JSON(workflow)
	})

	api.Post("/workflows", func(c *fiber.Ctx) error {
		var workflow models.Workflow
		if err := c.BodyParser(&workflow); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}
		if err := workflowStore.Save(workflow); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.Status(201).JSON(workflow)
	})

	api.Delete("/workflows/:id", func(c *fiber.Ctx) error {
		id := c.Params("id")
		if err := workflowStore.Delete(id); err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}
		return c.SendStatus(204)
	})

	api.Post("/workflows/:id/execute", func(c *fiber.Ctx) error {
		id := c.Params("id")
		var req struct {
			Variables map[string]string `json:"variables"`
		}
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		// Create a channel for streaming logs
		outputChan := make(chan string)

		// Start execution
		execution, err := workflowExecutor.Execute(c.Context(), id, req.Variables, outputChan)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		}

		// Stream output via WebSocket if connected, or just return execution ID
		// For now, we'll just return the execution object and let the client subscribe to logs via WS if needed
		// In a real implementation, we'd hook this into the existing WS infrastructure

		// Hook into existing WS for real-time logs
		go func() {
			for msg := range outputChan {
				clientsMu.Lock()
				wsMsg, _ := json.Marshal(fiber.Map{
					"type":         "workflow_log",
					"execution_id": execution.ID,
					"output":       msg,
					"timestamp":    time.Now(),
				})
				for client := range clients {
					client.WriteMessage(websocket.TextMessage, wsMsg)
				}
				clientsMu.Unlock()
			}
		}()

		return c.JSON(execution)
	})

	// Agent Data Sync
	api.Post("/sync/agent-data", func(c *fiber.Ctx) error {
		var data map[string]interface{}
		if err := c.BodyParser(&data); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": "Invalid data"})
		}

		logger.Info("Received agent data sync", logger.WithFields(map[string]interface{}{
			"timestamp": time.Now(),
			"data_keys": getMapKeys(data),
		}).Data)

		// Broadcast to connected clients
		clientsMu.Lock()
		defer clientsMu.Unlock()

		msg, _ := json.Marshal(fiber.Map{
			"type": "agent_sync",
			"data": data,
		})

		for client := range clients {
			if err := client.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("❌ Failed to broadcast agent sync: %v", err)
			}
		}

		return c.JSON(fiber.Map{"status": "synced"})
	})

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	logger.Info("Server starting", logger.WithFields(map[string]interface{}{
		"port":    port,
		"version": "2.0",
	}).Data)

	log.Printf("🚀 Server starting on port %s", port)
	if err := app.Listen(":" + port); err != nil {
		logger.Error("Failed to start server", err)
		log.Fatalf("Failed to start server: %v", err)
	}
}

func getMapKeys(m map[string]interface{}) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
