#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
PAGE_ID="${1:-}"
CONTENT="${2:-}"

if [ -z "$PAGE_ID" ] || [ -z "$CONTENT" ]; then
  echo "Usage: $0 <page_id> \"content\"" >&2
  exit 1
fi
block_payload=$(jq -n --arg content "$CONTENT" -c '
  {
    children: [
      {
        object: "block",
        type: "paragraph",
        paragraph: {
          rich_text: [
            {
              type: "text",
              text: { content: $content }
            }
          ]
        }
      }
    ]
  }
')
resp=$(notion_api PATCH "blocks/$PAGE_ID/children" "$block_payload")
if echo "$resp" | jq -e '.error' > /dev/null; then
  echo "$resp" | jq '.error' >&2
  exit 1
fi
echo "Block added to page $PAGE_ID"
echo "$resp" | jq '.'
