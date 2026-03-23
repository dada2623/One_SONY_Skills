#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAGE_ID="${1:-}"
UPDATES_JSON="${2:-}"

if [ -z "$PAGE_ID" ] || [ -z "$UPDATES_JSON" ]; then
  echo "Usage: $0 <page_id> '{\"属性名\":\"值\", ...}'" >&2
  echo "Example: $0 <page_id> '{\"状态\":\"已买\",\"优先级\":\"P1\"}'" >&2
  exit 1
fi

# Fetch page to learn property types
PAGE_RESP=$(notion_api GET "pages/$PAGE_ID")
if echo "$PAGE_RESP" | jq -e '.error' > /dev/null; then
  echo "$PAGE_RESP" | jq '.error' >&2
  exit 1
fi

# Build the properties update object entirely inside jq
UPDATE_PAYLOAD=$(jq -n \
  --argjson updates "$UPDATES_JSON" \
  --argjson pageSchema "$PAGE_RESP" \
  '
    {
      properties: (
        $updates
        | to_entries
        | map(
            .key as $k
            | .value as $v
            | $pageSchema.properties[$k].type as $type
            | if $type == "title" then
                {($k): {title: [{text: {content: $v}}]}}
              elif $type == "rich_text" then
                {($k): {rich_text: [{text: {content: $v}}]}}
              elif $type == "select" or $type == "status" then
                {($k): {$type: {name: $v}}}
              elif $type == "number" then
                {($k): {number: $v}}
              elif $type == "url" then
                {($k): {url: $v}}
              elif $type == "checkbox" then
                {($k): {checkbox: ($v | test("^(true|1|yes|on)$"))}}
              elif $type == "date" then
                {($k): {date: {start: $v}}}
              else
                empty
              end
          )
        | add
      )
    }
  ')

# Perform update
UPDATE_RESP=$(notion_api PATCH "pages/$PAGE_ID" "$UPDATE_PAYLOAD")
if echo "$UPDATE_RESP" | jq -e '.error' > /dev/null; then
  echo "$UPDATE_RESP" | jq '.error' >&2
  exit 1
fi

echo "Page updated: $PAGE_ID"
echo "$UPDATE_RESP" | jq '.'
