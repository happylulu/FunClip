#!/bin/bash

echo "🧪 Testing YouTube URL with Backend Integration"
echo "=============================================="
echo ""

# Backend URL
BACKEND_URL="http://147.182.255.74:8000"
YOUTUBE_URL="https://www.youtube.com/watch?v=dQw4w9WgXcQ"

echo "1️⃣ Testing Backend Health..."
curl -s "$BACKEND_URL/health" | python3 -m json.tool || echo "❌ Backend not reachable"

echo ""
echo "2️⃣ Testing YouTube URL Processing..."
echo "YouTube URL: $YOUTUBE_URL"
echo ""

# Create request payload
PAYLOAD=$(cat <<EOF
{
  "youtube_url": "$YOUTUBE_URL",
  "user_id": "test-user-123"
}
EOF
)

echo "Sending request to backend..."
echo ""

# Send request to backend
RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/v1/videos/youtube" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [ -z "$RESPONSE" ]; then
  echo "❌ No response from backend"
  echo ""
  echo "Let's check if the endpoint exists..."
  curl -s "$BACKEND_URL/api/v1/videos" || echo "Videos endpoint not found"
else
  echo "✅ Response received:"
  echo "$RESPONSE" | python3 -m json.tool
fi

echo ""
echo "=============================================="
echo "3️⃣ Testing with FunClip's Gradio backend..."
echo ""

# Try the original FunClip endpoint
curl -s -X POST "http://localhost:7860/api/process_youtube" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"$YOUTUBE_URL\"}" | python3 -m json.tool || echo "Gradio not running"

echo ""
echo "Test complete!"