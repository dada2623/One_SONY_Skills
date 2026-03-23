#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/common.sh"

PAGE_ID="${1:-}"
INCLUDE_BLOCKS="${2:-true}"

if [ -z "$PAGE_ID" ]; then
  echo "Usage: $0 <page_id> [include_blocks: true|false]" >&2
  exit 1
fi
echo "Fetching page $PAGE_ID..."
page_resp=$(notion_api GET "pages/$PAGE_ID")
if echo "$page_resp" | jq -e '.error' > /dev/null; then
  echo "$page_resp" | jq '.error' >&2
  exit 1
fi
echo "Properties:"
echo "$page_resp" | jq '.properties'
if [ "$INCLUDE_BLOCKS" = "true" ] || [ "$INCLUDE_BLOCKS" = "1" ]; then
  echo ""
  echo "Blocks:"
  block_resp=$(notion_api GET "blocks/$PAGE_ID/children")
  if echo "$block_resp" | jq -e '.error' > /dev/null; then
      echo "$block_resp" | jq '.error' >&2
      exit 1
    fi
    echo "$block_resp" | jq '.results[] | {type: .type, text: (.paragraph.rich_text[0].text.content // empty)}'
  fi
fi
