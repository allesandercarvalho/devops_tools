# DevOps Tools Backend - v2.0

Production-ready backend API with advanced command execution, queuing, metrics, and logging.

## 🚀 Quick Start

```bash
# Build
go build -o server ./cmd/server

# Run
PORT=3003 LOG_LEVEL=info ./server

# Test
./test_phase2.sh
```

## ✨ Features

### Core Features
- ✅ Real command execution with `os/exec`
- ✅ WebSocket streaming for real-time output
- ✅ Command whitelist security
- ✅ Command history persistence

### Phase 2 Features
- ✅ Command queue (FIFO, max 100)
- ✅ Concurrent execution (5 workers)
- ✅ Structured JSON logging
- ✅ Performance metrics
- ✅ Real-time progress tracking

## 📡 API Endpoints

### Commands
```bash
# Execute command
POST /api/commands/execute
{
  "command": "aws",
  "args": ["s3", "ls"],
  "work_dir": "/path"
}

# Get execution status
GET /api/commands/:id

# Get command history
GET /api/commands/history
```

### Queue
```bash
# Create queue
POST /api/queue
{
  "name": "Deploy Pipeline",
  "commands": ["cmd-id-1", "cmd-id-2"]
}

# Get queue status
GET /api/queue/:id

# Execute queue
POST /api/queue/:id/execute
```

### Metrics
```bash
# Get all metrics
GET /api/metrics

# Reset metrics (testing)
POST /api/metrics/reset
```

### WebSocket
```bash
# Connect
ws://localhost:3003/ws

# Messages:
# - command_output: Real-time command output
# - command_progress: Progress updates
# - sync_event: Configuration sync events
```

## 🔧 Configuration

### Environment Variables
```bash
PORT=3003                 # Server port (default: 3000)
LOG_DIR=./logs           # Log directory (default: ./logs)
LOG_LEVEL=info           # Log level: debug, info, warn, error
```

### Command Whitelist
Allowed commands:
- `aws`, `terraform`, `kubectl`, `argocd`
- `git`, `docker`, `helm`
- `gcloud`, `az`
- `ping`, `curl`, `dig`, `nslookup`, `traceroute`

## 📊 Metrics

### Available Metrics
- **Commands**: Total executions, success rate, avg duration
- **API**: Request count, error rate, response time
- **System**: Active commands, queued commands
- **Per-Command**: Individual command statistics

### Example Response
```json
{
  "summary": {
    "commands": {
      "total_executions": 150,
      "successes": 145,
      "failures": 5,
      "success_rate": 96.67,
      "avg_duration_ms": 1234
    },
    "api": {
      "total_requests": 500,
      "errors": 10,
      "error_rate": 2.0,
      "avg_response_time_ms": 45
    },
    "system": {
      "active_commands": 3,
      "queued_commands": 7
    }
  }
}
```

## 📝 Logging

### Log Format
```json
{
  "timestamp": "2024-12-01T07:22:00-03:00",
  "level": "info",
  "message": "Server starting",
  "port": "3003",
  "version": "2.0"
}
```

### Log Levels
- `debug`: Detailed debugging information
- `info`: General informational messages
- `warn`: Warning messages
- `error`: Error messages

### Log Rotation
- **Daily**: New file each day
- **Size-based**: 100MB max file size
- **Retention**: 7 days (manual cleanup)

## 🏗️ Architecture

```
Frontend (Flutter)
       ↓
Backend API (Fiber)
       ↓
┌──────────────────────────────┐
│  Command Queue (5 workers)   │
│         ↓                     │
│  Command Service             │
│         ↓                     │
│  os/exec → CLI Tools         │
└──────────────────────────────┘
       ↓
WebSocket → Real-time Updates
       ↓
Metrics Collector
       ↓
Logger (JSON, Rotation)
```

## 🔒 Security

- ✅ Command whitelist validation
- ✅ No shell injection (direct exec)
- ✅ User isolation
- ✅ Timeout protection
- ✅ Proper error handling
- ✅ Structured logging (no sensitive data)

## 🧪 Testing

### Manual Testing
```bash
# Run test script
./test_phase2.sh

# Or test individually
curl http://localhost:3003/health
curl http://localhost:3003/api/metrics
```

### WebSocket Testing
```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c ws://localhost:3003/ws

# Execute command in another terminal
curl -X POST http://localhost:3003/api/commands/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "echo", "args": ["test"]}'

# Watch real-time output in wscat
```

## 📁 Project Structure

```
backend/
├── cmd/
│   └── server/
│       └── main.go              # Entry point
├── internal/
│   ├── logger/
│   │   └── logger.go            # Structured logging
│   ├── metrics/
│   │   └── metrics.go           # Metrics collection
│   ├── models/
│   │   ├── command.go           # Command models
│   │   ├── models.go            # Core models
│   │   └── queue.go             # Queue models
│   ├── services/
│   │   ├── command.go           # Command execution
│   │   └── queue.go             # Queue management
│   └── store/
│       └── memory.go            # In-memory store
├── logs/                        # Log files
├── go.mod                       # Dependencies
├── go.sum                       # Dependency checksums
├── server                       # Compiled binary
├── test_phase2.sh              # Test script
├── PHASE2_SUMMARY.md           # Phase 2 summary
└── README.md                   # This file
```

## 🔄 Development Workflow

### 1. Make Changes
```bash
# Edit code
vim internal/services/command.go

# Build
go build -o server ./cmd/server
```

### 2. Test
```bash
# Run server
PORT=3003 ./server

# Test in another terminal
./test_phase2.sh
```

### 3. Monitor
```bash
# Watch logs
tail -f logs/backend-$(date +%Y-%m-%d).log | jq

# Check metrics
watch -n 1 'curl -s http://localhost:3003/api/metrics | jq .summary'
```

## 📚 Documentation

- **Implementation Plan**: `backend_phase2_plan.md`
- **Walkthrough**: `walkthrough.md` (in artifacts)
- **Complete Summary**: `complete_summary.md` (in artifacts)
- **Phase 2 Summary**: `PHASE2_SUMMARY.md`

## 🐛 Troubleshooting

### Server won't start
```bash
# Check if port is in use
lsof -i :3003

# Kill existing process
kill -9 <PID>

# Try different port
PORT=3004 ./server
```

### Logs not appearing
```bash
# Check log directory
ls -la logs/

# Check permissions
chmod 755 logs/

# Check LOG_DIR env var
echo $LOG_DIR
```

### Commands failing
```bash
# Check whitelist
grep -A 20 "commandWhitelist" internal/services/command.go

# Check command exists
which aws terraform kubectl

# Check logs for errors
tail -f logs/backend-*.log | grep error
```

## 🔮 Future Enhancements

- [ ] Command scheduling (cron-like)
- [ ] Retry logic with exponential backoff
- [ ] Command templates
- [ ] Prometheus metrics export
- [ ] Grafana dashboards
- [ ] Rate limiting
- [ ] Circuit breaker
- [ ] Multi-user support

## 📄 License

Internal project - Amigo Tech

## 👥 Contributors

- Autonomous AI Development

---

**Version**: 2.0
**Status**: Production Ready
**Last Updated**: 2024-12-01
