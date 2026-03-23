#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAGE_TITLE="${1:-}"
PAGE_CONTENT="${2:-}"

if [ -z "$PAGE_TITLE" ]; then
  echo "Usage: $0 \"Page Title\" [content]" >&2
  exit 1
fi

# Resolve data source and title property
DATA_SOURCE_ID=$(get_data_source_id "$WISHLIST_DB_ID")
TITLE_PROP=$(get_title_property "$DATA_SOURCE_ID")

# Create page
echo "Creating page: $PAGE_TITLE..."
CREATE_PAYLOAD=$(jq -n \
  --arg db "$WISHLIST_DB_ID" \
  --arg title "$PAGE_TITLE" \
  --arg prop "$TITLE_PROP" \
  '{parent: {database_id: $db}, properties: {($prop): {title: [{text: {content: $title}}]}}}')
CREATE_RESP=$(notion_api POST "pages" "$CREATE_PAYLOAD")

if echo "$CREATE_RESP" | jq -e '.error' > /dev/null; then
  echo "$CREATE_RESP" | jq '.error' >&2
  exit 1
fi

PAGE_ID=$(echo "$CREATE_RESP" | jq -r '.id')
echo "Page created: $PAGE_ID"

# Add content block if provided
if [ -n "$PAGE_CONTENT" ]; then
  echo "Adding content block..."
  BLOCK_PAYLOAD=$(jq -n --arg content "$PAGE_CONTENT" -c '
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
  BLOCK_RESP=$(notion_api PATCH "blocks/$PAGE_ID/children" "$BLOCK_PAYLOAD")
  if echo "$BLOCK_RESP" | jq -e '.error' > /dev/null; then
    echo "$BLOCK_RESP" | jq '.error' >&2
    exit 1
  fi
  echo "Content added."
fi

echo "URL: $(echo "$CREATE_RESP" | jq -r '.url')"
