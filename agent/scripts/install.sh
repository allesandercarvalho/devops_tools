#!/bin/bash
set -e

echo "🚀 Installing DevOps Tools Agent..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=macos;;
    *)          echo "❌ Unsupported OS: ${OS}"; exit 1;;
esac

echo "📦 Detected platform: ${PLATFORM}"

# Build agent
echo "🔨 Building agent..."
go build -o agent cmd/agent/main.go

if [ "${PLATFORM}" = "linux" ]; then
    echo "🐧 Installing for Linux (systemd)..."
    
    # Copy binary
    sudo mkdir -p /opt/devops-tools-agent
    sudo cp agent /opt/devops-tools-agent/
    sudo chmod +x /opt/devops-tools-agent/agent
    
    # Install systemd service
    sudo cp scripts/systemd/devops-tools-agent@.service /etc/systemd/system/
    
    # Enable and start service for current user
    sudo systemctl daemon-reload
    sudo systemctl enable devops-tools-agent@${USER}.service
    sudo systemctl start devops-tools-agent@${USER}.service
    
    echo "✅ Agent installed and started!"
    echo "📊 Check status: sudo systemctl status devops-tools-agent@${USER}.service"
    echo "📝 View logs: sudo journalctl -u devops-tools-agent@${USER}.service -f"
    
elif [ "${PLATFORM}" = "macos" ]; then
    echo "🍎 Installing for macOS (launchd)..."
    
    # Copy binary
    sudo mkdir -p /usr/local/bin
    sudo cp agent /usr/local/bin/devops-tools-agent
    sudo chmod +x /usr/local/bin/devops-tools-agent
    
    # Create working directory
    sudo mkdir -p /usr/local/var/devops-tools-agent
    sudo mkdir -p /usr/local/var/log
    
    # Install launchd service
    sudo cp scripts/launchd/com.devopstools.agent.plist /Library/LaunchDaemons/
    sudo chown root:wheel /Library/LaunchDaemons/com.devopstools.agent.plist
    
    # Load and start service
    sudo launchctl load /Library/LaunchDaemons/com.devopstools.agent.plist
    
    echo "✅ Agent installed and started!"
    echo "📊 Check status: sudo launchctl list | grep devopstools"
    echo "📝 View logs: tail -f /usr/local/var/log/devops-tools-agent.log"
fi

echo ""
echo "🎉 Installation complete!"
