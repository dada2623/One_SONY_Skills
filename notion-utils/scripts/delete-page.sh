#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_dir/common.sh"

PAGE_ID="${1:-}"

if [ -z "$PAGE_ID" ]; then
  echo "Usage: $0 <page_id>" >&2
  exit 1
fi
echo "Archiving page $PAGE_ID..."
archive_payload='{"archived": true}'
resp=$(notion_api PATCH "pages/$PAGE_ID" "$archive_payload")
if echo "$resp" | jq -e '.error' > /dev/null; then
  echo "$resp" | jq '.error' >&2
  exit 1
fi
echo "Page archived: $PAGE_ID"
echo "$resp" | jq '.'
