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
page_resp=$(notion_api GET "pages/$PAGE_ID")
if echo "$page_resp" | jq -e '.error' > /dev/null; then
  echo "$page_resp" | jq -r '.error.message // .error' >&2
  exit 1
fi
echo "Title: $(echo "$page_resp" | jq -r '.properties | to_entries[] | select(.value.type == "title") | .value.title[0].plain_text // "?"')"
echo "URL: $(echo "$page_resp" | jq -r '.url')"
echo "Properties:"
echo "$page_resp" | jq '.properties'
if [ "$INCLUDE_BLOCKS" = "true" ] || [ "$INCLUDE_BLOCKS" = "1" ]; then
  echo ""
  echo "Blocks:"
  block_resp=$(notion_api GET "blocks/$PAGE_ID/children")
  if echo "$block_resp" | jq -e '.error' > /dev/null; then
    echo "$block_resp" | jq -r '.error.message // .error' >&2
    exit 1
  fi
  echo "$block_resp" | jq -r '
    .results[]
    | if (.type | IN("paragraph", "heading_1", "heading_2", "heading_3", "bulleted_list_item", "numbered_list_item", "to_do", "quote", "callout")) then
        "\(.type): \(.[.type].rich_text | map(.plain_text // "") | join(""))"
      elif .type == "image" then
        "image: \(.image.external.url // .image.file.url // "(no url)")"
      else
        "\(.type): (no text)"
      end
  '
fi
