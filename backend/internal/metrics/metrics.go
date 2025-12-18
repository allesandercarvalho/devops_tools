package metrics

import (
	"sync"
	"time"
)

// Metrics collects and stores application metrics
type Metrics struct {
	mu sync.RWMutex

	// Command metrics
	CommandExecutions    int64
	CommandSuccesses     int64
	CommandFailures      int64
	CommandTotalDuration time.Duration
	CommandAvgDuration   time.Duration

	// API metrics
	APIRequests          int64
	APIErrors            int64
	APITotalResponseTime time.Duration
	APIAvgResponseTime   time.Duration

	// System metrics
	ActiveCommands int64
	QueuedCommands int64

	// Per-command metrics
	commandMetrics map[string]*CommandMetric
}

// CommandMetric tracks metrics for a specific command
type CommandMetric struct {
	Command       string
	Executions    int64
	Successes     int64
	Failures      int64
	TotalDuration time.Duration
	AvgDuration   time.Duration
	LastExecution time.Time
}

var globalMetrics *Metrics
var once sync.Once

// GetMetrics returns the global metrics instance
func GetMetrics() *Metrics {
	once.Do(func() {
		globalMetrics = &Metrics{
			commandMetrics: make(map[string]*CommandMetric),
		}
	})
	return globalMetrics
}

// RecordCommandExecution records a command execution
func (m *Metrics) RecordCommandExecution(command string, duration time.Duration, success bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.CommandExecutions++
	m.CommandTotalDuration += duration
	m.CommandAvgDuration = time.Duration(int64(m.CommandTotalDuration) / m.CommandExecutions)

	if success {
		m.CommandSuccesses++
	} else {
		m.CommandFailures++
	}

	// Update per-command metrics
	metric, ok := m.commandMetrics[command]
	if !ok {
		metric = &CommandMetric{
			Command: command,
		}
		m.commandMetrics[command] = metric
	}

	metric.Executions++
	metric.TotalDuration += duration
	metric.AvgDuration = time.Duration(int64(metric.TotalDuration) / metric.Executions)
	metric.LastExecution = time.Now()

	if success {
		metric.Successes++
	} else {
		metric.Failures++
	}
}

// RecordAPIRequest records an API request
func (m *Metrics) RecordAPIRequest(duration time.Duration, isError bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.APIRequests++
	m.APITotalResponseTime += duration
	m.APIAvgResponseTime = time.Duration(int64(m.APITotalResponseTime) / m.APIRequests)

	if isError {
		m.APIErrors++
	}
}

// IncrementActiveCommands increments active command count
func (m *Metrics) IncrementActiveCommands() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.ActiveCommands++
}

// DecrementActiveCommands decrements active command count
func (m *Metrics) DecrementActiveCommands() {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.ActiveCommands--
}

// SetQueuedCommands sets the queued command count
func (m *Metrics) SetQueuedCommands(count int64) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.QueuedCommands = count
}

// GetSnapshot returns a snapshot of current metrics
func (m *Metrics) GetSnapshot() map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	return map[string]interface{}{
		"commands": map[string]interface{}{
			"total_executions": m.CommandExecutions,
			"successes":        m.CommandSuccesses,
			"failures":         m.CommandFailures,
			"success_rate":     float64(m.CommandSuccesses) / float64(m.CommandExecutions) * 100,
			"avg_duration_ms":  m.CommandAvgDuration.Milliseconds(),
		},
		"api": map[string]interface{}{
			"total_requests":       m.APIRequests,
			"errors":               m.APIErrors,
			"error_rate":           float64(m.APIErrors) / float64(m.APIRequests) * 100,
			"avg_response_time_ms": m.APIAvgResponseTime.Milliseconds(),
		},
		"system": map[string]interface{}{
			"active_commands": m.ActiveCommands,
			"queued_commands": m.QueuedCommands,
		},
	}
}

// GetCommandMetrics returns metrics for all commands
func (m *Metrics) GetCommandMetrics() map[string]*CommandMetric {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[string]*CommandMetric)
	for k, v := range m.commandMetrics {
		result[k] = v
	}
	return result
}

// Reset resets all metrics
func (m *Metrics) Reset() {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.CommandExecutions = 0
	m.CommandSuccesses = 0
	m.CommandFailures = 0
	m.CommandTotalDuration = 0
	m.CommandAvgDuration = 0
	m.APIRequests = 0
	m.APIErrors = 0
	m.APITotalResponseTime = 0
	m.APIAvgResponseTime = 0
	m.ActiveCommands = 0
	m.QueuedCommands = 0
	m.commandMetrics = make(map[string]*CommandMetric)
}
