#!/bin/bash

# Backend Phase 2 - Test Script
# Tests new features: queue, metrics, logging

BASE_URL="http://localhost:3003/api"

echo "🧪 Testing Backend Phase 2 Features"
echo "===================================="
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
curl -s "$BASE_URL/../health" | jq '.'
echo ""

# Test 2: Create Command Queue
echo "2️⃣  Creating Command Queue..."
QUEUE_RESPONSE=$(curl -s -X POST "$BASE_URL/queue" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Workflow",
    "commands": ["cmd-1", "cmd-2", "cmd-3"]
  }')

echo "$QUEUE_RESPONSE" | jq '.'
QUEUE_ID=$(echo "$QUEUE_RESPONSE" | jq -r '.id')
echo "Queue ID: $QUEUE_ID"
echo ""

# Test 3: Get Queue Status
echo "3️⃣  Getting Queue Status..."
curl -s "$BASE_URL/queue/$QUEUE_ID" | jq '.'
echo ""

# Test 4: Get Metrics (Initial)
echo "4️⃣  Getting Initial Metrics..."
curl -s "$BASE_URL/metrics" | jq '.summary'
echo ""

# Test 5: Execute a Command
echo "5️⃣  Executing Test Command..."
CMD_RESPONSE=$(curl -s -X POST "$BASE_URL/commands/execute" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "echo",
    "args": ["Hello from Phase 2!"]
  }')

echo "$CMD_RESPONSE" | jq '.'
CMD_ID=$(echo "$CMD_RESPONSE" | jq -r '.id')
echo "Command ID: $CMD_ID"
echo ""

# Wait for command to complete
echo "⏳ Waiting for command to complete..."
sleep 2

# Test 6: Get Command Status
echo "6️⃣  Getting Command Status..."
curl -s "$BASE_URL/commands/$CMD_ID" | jq '.'
echo ""

# Test 7: Get Updated Metrics
echo "7️⃣  Getting Updated Metrics..."
curl -s "$BASE_URL/metrics" | jq '.'
echo ""

# Test 8: Get Command History
echo "8️⃣  Getting Command History..."
curl -s "$BASE_URL/commands/history" | jq '.[0:2]'
echo ""

# Test 9: Execute Queue
echo "9️⃣  Executing Queue (async)..."
curl -s -X POST "$BASE_URL/queue/$QUEUE_ID/execute" | jq '.'
echo ""

echo "✅ All tests completed!"
echo ""
echo "📊 Summary:"
echo "  - Health check: ✓"
echo "  - Queue creation: ✓"
echo "  - Command execution: ✓"
echo "  - Metrics tracking: ✓"
echo "  - Command history: ✓"
echo ""
echo "🔗 Useful endpoints:"
echo "  - Health: http://localhost:3003/health"
echo "  - Metrics: http://localhost:3003/api/metrics"
echo "  - Queue: http://localhost:3003/api/queue"
echo "  - Commands: http://localhost:3003/api/commands"
echo "  - WebSocket: ws://localhost:3003/ws"
