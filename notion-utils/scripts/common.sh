#!/bin/bash
set -e

NOTION_API_KEY="${NOTION_API_KEY:-$(cat ~/.config/notion/api_key 2>/dev/null || true)}"

if [ -z "$NOTION_API_KEY" ]; then
  echo "Error: NOTION_API_KEY not set and ~/.config/notion/api_key not found." >&2
  exit 1
fi

# Helper functions

notion_api() {
  local method="$1"
  local endpoint="$2"
  local payload="$3"
  curl -s -X "$method" "https://api.notion.com/v1/$endpoint" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2025-09-03" \
    -H "Content-Type: application/json" \
    ${payload:+-d "$payload"}
}

get_data_source_id() {
  local database_id="$1"
  # Search for the database to get its data_source_id
  local response
  response=$(notion_api POST "search" "{\"query\": \"\", \"filter\": {\"value\": \"database\", \"property\": \"object\"}}")
  # Find the database with matching database_id in the results
  echo "$response" | jq -r --arg db_id "$database_id" '.results[] | select(.id == $db_id or (.parent.database_id // "" == $db_id)) | .id' | head -n1
}

get_title_property() {
  local data_source_id="$1"
  local response
  response=$(notion_api GET "data_sources/$data_source_id")
  echo "$response" | jq -r '.properties | to_entries[] | select(.value.type == "title") | .key' | head -n1
}