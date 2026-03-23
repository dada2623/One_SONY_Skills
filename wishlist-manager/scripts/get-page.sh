#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAGE_ID="${1:-}"
INCLUDE_BLOCKS="${2:-true}"

if [ -z "$PAGE_ID" ]; then
  echo "Usage: $0 <page_id> [include_blocks: true|false]" >&2
  exit 1
fi

echo "Fetching page $PAGE_ID..."
PAGE_RESP=$(notion_api GET "pages/$PAGE_ID")
if echo "$PAGE_RESP" | jq -e '.error' > /dev/null; then
  echo "$PAGE_RESP" | jq '.error' >&2
  exit 1
fi

echo "Properties:"
echo "$PAGE_RESP" | jq '.properties'

if [ "$INCLUDE_BLOCKS" = "true" ] || [ "$INCLUDE_BLOCKS" = "1" ]; then
  echo ""
  echo "Blocks:"
  BLOCK_RESP=$(notion_api GET "blocks/$PAGE_ID/children")
  if echo "$BLOCK_RESP" | jq -e '.error' > /dev/null; then
    echo "$BLOCK_RESP" | jq '.error' >&2
    exit 1
  fi
  echo "$BLOCK_RESP" | jq '.results[] | {type: .type, text: (.paragraph.rich_text[0].text.content // empty)}'
fi
