#!/bin/bash

# Integration Test Script - Phase 5
# Verifies bidirectional sync and agent data collection

BASE_URL="http://localhost:3003/api"
AGENT_SYNC_URL="$BASE_URL/sync/agent-data"

echo "🧪 Starting Integration Tests"
echo "============================"
echo ""

# Test 1: Simulate Agent Data Sync
echo "1️⃣  Simulating Agent Data Sync..."
SYNC_RESPONSE=$(curl -s -X POST "$AGENT_SYNC_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2024-12-01T12:00:00Z",
    "aws": {
      "stacks": [{"stack_name": "test-stack", "status": "CREATE_COMPLETE"}]
    },
    "terraform": {
      "workspaces": [{"name": "default", "current": true}]
    },
    "kubernetes": {
      "contexts": [{"name": "minikube", "current": true}]
    }
  }')

echo "Response: $SYNC_RESPONSE"
echo ""

# Test 2: Verify WebSocket Broadcast (Manual Check)
echo "2️⃣  WebSocket Verification"
echo "   (Check backend logs for 'Received agent data sync' and 'Broadcast to connected clients')"
echo ""

# Test 3: Verify Metrics
echo "3️⃣  Checking Metrics..."
curl -s "$BASE_URL/metrics" | jq '.summary'
echo ""

echo "✅ Integration tests completed!"
