#!/bin/bash
set -e

echo "🛑 Uninstalling DevOps Tools Agent..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=macos;;
    *)          echo "❌ Unsupported OS: ${OS}"; exit 1;;
esac

if [ "${PLATFORM}" = "linux" ]; then
    echo "🐧 Uninstalling from Linux..."
    
    # Stop and disable service
    sudo systemctl stop devops-tools-agent@${USER}.service || true
    sudo systemctl disable devops-tools-agent@${USER}.service || true
    
    # Remove files
    sudo rm -f /etc/systemd/system/devops-tools-agent@.service
    sudo rm -rf /opt/devops-tools-agent
    
    sudo systemctl daemon-reload
    
elif [ "${PLATFORM}" = "macos" ]; then
    echo "🍎 Uninstalling from macOS..."
    
    # Unload and remove service
    sudo launchctl unload /Library/LaunchDaemons/com.devopstools.agent.plist || true
    sudo rm -f /Library/LaunchDaemons/com.devopstools.agent.plist
    
    # Remove files
    sudo rm -f /usr/local/bin/devops-tools-agent
    sudo rm -rf /usr/local/var/devops-tools-agent
fi

echo "✅ Agent uninstalled successfully!"
