#!/bin/bash
set -e

if [ -z "$PROJECT_ID" ] || [ -z "$EI_API_KEY" ]; then
  echo "ERROR: Please set PROJECT_ID and EI_API_KEY"
  exit 1
fi

RESP=$( curl -s -X POST https://studio.edgeimpulse.com/v1/api/${PROJECT_ID}/jobs/retrain -H "x-api-key: ${EI_API_KEY}" -H "Content-Type: application/json" -d '{}')

SUCCESS=$(echo "$RESP" | jq -r '.success')

if [ "$SUCCESS" != "true" ]; then
  echo "ERROR: Retrain failed"
  echo "$RESP"
  exit 1
fi

JOB_ID=$(echo "$RESP" | jq -r '.id')

echo "$JOB_ID"
