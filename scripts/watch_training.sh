#!/bin/bash
set -e

JOB_ID="$1"

if [ -z "$JOB_ID" ]; then
  echo "ERROR: JOB_ID required"
  exit 1
fi

if [ -z "$PROJECT_ID" ] || [ -z "$EI_API_KEY" ]; then
  echo "ERROR: PROJECT_ID and EI_API_KEY must be set"
  exit 1
fi

API="https://studio.edgeimpulse.com/v1/api/${PROJECT_ID}/jobs"

LAST_COMPUTE_TIME=-1
SAME_COUNT=0
MAX_SAME=3

echo "Monitoring training job ${JOB_ID}..."

while true; do
  RESP=$(curl -s -H "x-api-key: ${EI_API_KEY}" "$API")

  JOB=$(echo "$RESP" | jq -c --arg id "$JOB_ID" '
    .jobs[]
    | select(.id == ($id | tonumber))
  ')

  if [ -z "$JOB" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') training finished"
    exit 0
  fi

  COMPUTE_TIME=$(echo "$JOB" | jq -r '.computeTime')

  if [ "$COMPUTE_TIME" -eq "$LAST_COMPUTE_TIME" ]; then
    SAME_COUNT=$((SAME_COUNT + 1))
  else
    SAME_COUNT=0
    LAST_COMPUTE_TIME="$COMPUTE_TIME"
  fi

  if [ "$COMPUTE_TIME" -gt 0 ] && [ "$SAME_COUNT" -ge "$MAX_SAME" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') training finished(computeTime=${COMPUTE_TIME}s)"
    exit 0
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') training running..."
  fi

  sleep 10
done
