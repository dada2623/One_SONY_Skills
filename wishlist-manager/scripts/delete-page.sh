#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAGE_ID="${1:-}"

if [ -z "$PAGE_ID" ]; then
  echo "Usage: $0 <page_id>" >&2
  exit 1
fi

echo "Archiving page $PAGE_ID..."
ARCHIVE_PAYLOAD='{"archived": true}'
RESP=$(notion_api PATCH "pages/$PAGE_ID" "$ARCHIVE_PAYLOAD")
if echo "$RESP" | jq -e '.error' > /dev/null; then
  echo "$RESP" | jq '.error' >&2
  exit 1
fi

echo "Page archived: $PAGE_ID"
echo "$RESP" | jq '.'
