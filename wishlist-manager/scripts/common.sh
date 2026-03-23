#!/bin/bash
set -e

# Read Notion API key (~/.config/notion/api_key)
NOTION_API_KEY="${NOTION_API_KEY:-$(cat ~/.config/notion/api_key 2>/dev/null || true)}"
if [ -z "$NOTION_API_KEY" ]; then
  echo "Error: NOTION_API_KEY not set and ~/.config/notion/api_key not found." >&2
  exit 1
fi

# Default Wishlist database ID
WISHLIST_DB_ID="${WISHLIST_DB_ID:-c1b6e15bc8e5472897f80fa3b0a18a02}"

# API helper
notion_api() {
  local method=$1
  local endpoint=$2
  local data=$3
  local args=(-s -X "$method" "https://api.notion.com/v1/$endpoint")
  [ -n "$data" ] && args+=(-d "$data")
  curl "${args[@]}" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2025-09-03" \
    -H "Content-Type: application/json"
}

# Resolve data_source_id from linked database
get_data_source_id() {
  local db_id=$1
  local resp
  resp=$(notion_api GET "databases/$db_id")
  if echo "$resp" | jq -e '.error' > /dev/null; then
    echo "$resp" >&2
    return 1
  fi
  echo "$resp" | jq -r '.data_sources[0].id // empty'
}

# Fetch data source schema and return title property name
get_title_property() {
  local ds_id=$1
  local resp
  resp=$(notion_api GET "data_sources/$ds_id")
  if echo "$resp" | jq -e '.error' > /dev/null; then
    echo "$resp" >&2
    return 1
  fi
  echo "$resp" | jq -r '.properties | to_entries[] | select(.value.title) | .key // empty'
}
