# DevOps Tools

Universal CLI management platform with bidirectional sync between web/desktop apps and local machine configurations.

## Features

- 🔄 **Bidirectional Sync**: Changes made in the app or terminal are automatically synchronized
- 🔐 **Secure**: AES-256-GCM encryption for secrets
- 🌐 **Cross-Platform**: Web and desktop (macOS, Windows, Linux)
- 🛠️ **Multi-Tool Support**: AWS, kubectl, Terraform, ArgoCD, and more
- 📱 **Multi-Device**: Sync configurations across all your devices
- 📊 **Command History**: Track and replay commands
- 📚 **Knowledge Base**: Built-in documentation and best practices

## Architecture

```
┌─────────────────┐
│  Flutter App    │ (Web/Desktop)
│  (Frontend)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Go Backend     │ (API Server)
│  + Supabase     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Local Agent    │ (Go Daemon)
│  File Watcher   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Config Files   │ (~/.aws, ~/.kube, etc.)
└─────────────────┘
```

## Quick Start

### Backend

```bash
cd backend
go run cmd/server/main.go
```

### Agent

```bash
cd agent
go run cmd/agent/main.go
```

### Frontend

```bash
cd frontend
flutter run -d chrome  # For web
flutter run -d macos   # For macOS desktop
```

## Project Structure

```
devops-tools/
├── frontend/          # Flutter application
├── backend/           # Go API server
├── agent/             # Local sync agent
├── shared/            # Shared models
└── docs/              # Documentation
```

## Development Status

- ✅ Project structure created
- ✅ Backend API with Fiber
- ✅ Encryption utilities (AES-256-GCM)
- ✅ Filesystem watcher
- ✅ AWS config parser
- 🚧 Supabase integration
- 🚧 Flutter UI
- 🚧 Sync engine
- 🚧 kubectl parser
- 🚧 Terraform parser

## License

MIT
