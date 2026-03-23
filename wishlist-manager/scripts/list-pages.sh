#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DATA_SOURCE_ID=$(get_data_source_id "$WISHLIST_DB_ID")
TITLE_PROP=$(get_title_property "$DATA_SOURCE_ID")

# Optional: try to sort by "创建时间" if exists
QUERY='{}'
if jq -e --arg prop "创建时间" '.properties[$prop]' <<<"$(notion_api GET "data_sources/$DATA_SOURCE_ID")" >/dev/null 2>&1; then
  QUERY=$(jq -n --arg ts "创建时间" '{sorts: [{property: $ts, direction: "descending"}]}')
fi

echo "Fetching pages..."
RESP=$(notion_api POST "data_sources/$DATA_SOURCE_ID/query" "$QUERY")
if echo "$RESP" | jq -e '.error' > /dev/null; then
  echo "$RESP" | jq '.error' >&2
  exit 1
fi

# Header
printf "%-36s | %s | %s\n" "ID" "Title" "URL"
echo "---------------------------------------------"

echo "$RESP" | jq -r --arg titleProp "$TITLE_PROP" '.results[] | "\(.id) | \(.properties[$titleProp].title[0].text.content // "?") | \(.url)"' | while IFS='|' read -r id title url; do
  printf "%-36s | %s | %s\n" "$id" "$title" "$url"
done
