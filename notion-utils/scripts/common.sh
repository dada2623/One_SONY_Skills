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
  if [ -n "$payload" ]; then
    local tmpfile
    tmpfile=$(mktemp) || exit 1
    printf '%s' "$payload" > "$tmpfile"
    curl -s -X "$method" "https://api.notion.com/v1/$endpoint" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json" \
      --data "@$tmpfile"
    rm -f "$tmpfile"
  else
    curl -s -X "$method" "https://api.notion.com/v1/$endpoint" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json"
  fi
}

get_data_source_id() {
  local database_id="$1"
  # Normalize: remove hyphens for comparison (API returns hyphenated IDs)
  local normalized_id="${database_id//-/}"
  # Search for the database to get its data_source_id
  local response
  response=$(notion_api POST "search" "{\"query\": \"\", \"filter\": {\"value\": \"database\", \"property\": \"object\"}}")
  # Normalize both sides: strip hyphens from API response id before comparison
  echo "$response" | jq -r --arg db_id "$normalized_id" '.results[] | select((.id | gsub("-"; "")) == $db_id) | .id' | head -n1
}

get_title_property() {
  local database_id="$1"
  local response
  response=$(notion_api GET "databases/$database_id")
  echo "$response" | jq -r '.properties | to_entries[] | select(.value.type == "title") | .key' | head -n1
}