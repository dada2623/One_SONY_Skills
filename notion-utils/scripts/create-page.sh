#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DATABASE_ID="${DATABASE_ID:-}"
PAGE_TITLE="${1:-}"
PAGE_CONTENT="${2:-}"

if [ -z "$DATABASE_ID" ]; then
  echo "Error: DATABASE_ID not set. Set DATABASE_id=<database_id> or use -d option." >&2
  exit 1
fi
if [ -z "$PAGE_TITLE" ]; then
  echo "Usage: $0 <database_id> \"Page Title\" [content]" >&2
  exit 1
fi
DATA_SOURCE_ID=$(get_data_source_id "$DATABASE_ID")
TITLE_PROP=$(get_title_property "$DATA_source_id")
echo "Creating page: $PAGE_TITLE..."
CREATE_payload=$(jq -n \
  --arg db "$DATABASE_ID" \
  --arg title "$PAGE_TITLE" \
    --arg prop "$TITLE_PROP" \
  '{parent: {database_id: $db}, properties: {($prop): {title: [{text: {content: $title}}]}}')
create_resp=$(notion_api POST "pages" "$create_payload")

if echo "$create_resp" | jq -e '.error' > /dev/null; then
  echo "$create_resp" | jq '.error' >&2
  exit 1
fi
page_id=$(echo "$create_resp" | jq -r '.id')
echo "Page created: $page_id"
if [ -n "$PAGE_CONTENT" ]; then
  echo "Adding content block..."
  block_payload=$(jq -n --arg content "$PAGE_CONTENT" -c '
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
  block_resp=$(notion_api PATCH "blocks/$page_id/children" "$block_payload")
  if echo "$block_resp" | jq -e '.error' > /dev/null; then
    echo "$block_resp" | jq '.error' >&2
    exit 1
  fi
  echo "Content added."
fi
echo "URL: $(echo "$create_resp" | jq -r '.url')
