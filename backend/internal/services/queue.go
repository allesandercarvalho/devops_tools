package services

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/devopstools/backend/internal/models"
	"github.com/google/uuid"
)

// CommandQueue manages queued command execution
type CommandQueue struct {
	queue          chan *models.CommandExecution
	maxConcurrent  int
	activeCommands sync.WaitGroup
	cmdService     *CommandService
	onProgress     func(progress models.CommandProgress)
	mu             sync.RWMutex
	queues         map[string]*models.CommandQueue
}

// NewCommandQueue creates a new command queue
func NewCommandQueue(cmdService *CommandService, maxConcurrent int) *CommandQueue {
	cq := &CommandQueue{
		queue:         make(chan *models.CommandExecution, 100),
		maxConcurrent: maxConcurrent,
		cmdService:    cmdService,
		queues:        make(map[string]*models.CommandQueue),
	}

	// Start workers
	for i := 0; i < maxConcurrent; i++ {
		go cq.worker()
	}

	return cq
}

// SetProgressCallback sets the callback for progress updates
func (cq *CommandQueue) SetProgressCallback(callback func(progress models.CommandProgress)) {
	cq.onProgress = callback
}

// Enqueue adds a command to the queue
func (cq *CommandQueue) Enqueue(ctx context.Context, userID, command string, args []string, workDir string, timeout time.Duration) (*models.CommandExecution, error) {
	execution := &models.CommandExecution{
		ID:        uuid.New().String(),
		UserID:    userID,
		Command:   command,
		Args:      args,
		WorkDir:   workDir,
		Status:    "queued",
		StartedAt: time.Now(),
	}

	// Send progress update
	if cq.onProgress != nil {
		cq.onProgress(models.CommandProgress{
			ExecutionID: execution.ID,
			Step:        "queued",
			Percentage:  0,
			Message:     "Command queued for execution",
			Timestamp:   time.Now(),
		})
	}

	// Add to queue
	select {
	case cq.queue <- execution:
		return execution, nil
	default:
		return nil, fmt.Errorf("queue is full")
	}
}

// worker processes commands from the queue
func (cq *CommandQueue) worker() {
	for execution := range cq.queue {
		cq.activeCommands.Add(1)
		cq.processCommand(execution)
		cq.activeCommands.Done()
	}
}

// processCommand executes a single command
func (cq *CommandQueue) processCommand(execution *models.CommandExecution) {
	// Update status
	execution.Status = "running"

	// Send progress update
	if cq.onProgress != nil {
		cq.onProgress(models.CommandProgress{
			ExecutionID: execution.ID,
			Step:        "starting",
			Percentage:  10,
			Message:     "Starting command execution",
			Timestamp:   time.Now(),
		})
	}

	// Execute command with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Use the command service to execute
	result, err := cq.cmdService.Execute(ctx, execution.UserID, execution.Command, execution.Args, execution.WorkDir)

	if err != nil {
		execution.Status = "failed"
		execution.Error = err.Error()
	} else {
		execution.Status = result.Status
		execution.Output = result.Output
		execution.ExitCode = result.ExitCode
	}

	// Send completion progress
	if cq.onProgress != nil {
		percentage := 100.0
		if execution.Status == "failed" {
			percentage = 0
		}

		cq.onProgress(models.CommandProgress{
			ExecutionID: execution.ID,
			Step:        "completed",
			Percentage:  percentage,
			Message:     fmt.Sprintf("Command %s", execution.Status),
			Timestamp:   time.Now(),
		})
	}
}

// CreateQueue creates a new command queue
func (cq *CommandQueue) CreateQueue(userID, name string, commands []string) (*models.CommandQueue, error) {
	cq.mu.Lock()
	defer cq.mu.Unlock()

	queue := &models.CommandQueue{
		ID:          uuid.New().String(),
		UserID:      userID,
		Name:        name,
		Commands:    commands,
		Status:      "pending",
		CurrentStep: 0,
		CreatedAt:   time.Now(),
	}

	cq.queues[queue.ID] = queue
	return queue, nil
}

// GetQueue retrieves a queue by ID
func (cq *CommandQueue) GetQueue(id string) (*models.CommandQueue, error) {
	cq.mu.RLock()
	defer cq.mu.RUnlock()

	queue, ok := cq.queues[id]
	if !ok {
		return nil, fmt.Errorf("queue not found: %s", id)
	}
	return queue, nil
}

// ExecuteQueue executes all commands in a queue sequentially
func (cq *CommandQueue) ExecuteQueue(ctx context.Context, queueID string) error {
	queue, err := cq.GetQueue(queueID)
	if err != nil {
		return err
	}

	cq.mu.Lock()
	queue.Status = "running"
	now := time.Now()
	queue.StartedAt = &now
	cq.mu.Unlock()

	// Execute commands sequentially
	for i, cmdID := range queue.Commands {
		cq.mu.Lock()
		queue.CurrentStep = i
		cq.mu.Unlock()

		// Get command execution
		execution, err := cq.cmdService.GetExecution(cmdID)
		if err != nil {
			cq.mu.Lock()
			queue.Status = "failed"
			cq.mu.Unlock()
			return err
		}

		// Execute
		_, err = cq.cmdService.Execute(ctx, queue.UserID, execution.Command, execution.Args, execution.WorkDir)
		if err != nil {
			cq.mu.Lock()
			queue.Status = "failed"
			cq.mu.Unlock()
			return err
		}
	}

	cq.mu.Lock()
	queue.Status = "completed"
	now = time.Now()
	queue.CompletedAt = &now
	cq.mu.Unlock()

	return nil
}

// Wait waits for all active commands to complete
func (cq *CommandQueue) Wait() {
	cq.activeCommands.Wait()
}

// Close closes the queue
func (cq *CommandQueue) Close() {
	close(cq.queue)
	cq.Wait()
}
