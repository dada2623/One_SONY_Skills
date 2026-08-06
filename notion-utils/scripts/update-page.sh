#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

PAGE_ID="${1:-}"
UPDATES_JSON="${2:-}"

if [ -z "$PAGE_ID" ] || [ -z "$UPDATES_JSON" ]; then
  echo "Usage: $0 <page_id> '<json>' | $0 <page_id> <updates.json>" >&2
  echo "  inline JSON: $0 <page_id> '{\"进行状态\":\"看过\",\"观看方式\":[\"电视\"]}'" >&2
  echo "  JSON file:   $0 <page_id> /path/to/updates.json (or @/path/to/updates.json)" >&2
  exit 1
fi

# Accept a JSON file path (or @path) instead of an inline string to avoid shell escaping issues
if [[ "$UPDATES_JSON" == \{* ]]; then
  : # inline JSON object
elif [ -f "$UPDATES_JSON" ]; then
  echo "Reading updates from file: $UPDATES_JSON"
  UPDATES_JSON=$(cat "$UPDATES_JSON")
elif [[ "$UPDATES_JSON" == @* ]] && [ -f "${UPDATES_JSON:1}" ]; then
  echo "Reading updates from file: ${UPDATES_JSON:1}"
  UPDATES_JSON=$(cat "${UPDATES_JSON:1}")
else
  echo "Error: second argument must be a JSON object or a path to an existing JSON file." >&2
  exit 1
fi

# Validate the updates payload is a JSON object
if ! echo "$UPDATES_JSON" | jq -e 'type == "object"' > /dev/null 2>&1; then
  echo "Error: updates must be a JSON object, got: $UPDATES_JSON" >&2
  exit 1
fi

echo "Fetching page to learn property types..."
page_resp=$(notion_api GET "pages/$PAGE_ID")
if echo "$page_resp" | jq -e '.error' > /dev/null; then
  echo "$page_resp" | jq -r '.error.message // .error' >&2
  exit 1
fi
update_payload=$(jq -n \
  --argjson updates "$UPDATES_JSON" \
  --argjson pageSchema "$page_resp" \
  '
    {
      properties: (
        $updates
        | to_entries
        | map(
            .key as $k
            | .value as $v
            | ($pageSchema.properties[$k].type // "unknown") as $type
            | if $type == "title" then
                {($k): {title: [{text: {content: $v}}]}}
              elif $type == "rich_text" then
                {($k): {rich_text: [{text: {content: $v}}]}}
              elif $type == "select" or $type == "status" then
                {($k): {$type: {name: $v}}}
              elif $type == "multi_select" then
                {($k): {multi_select: (
                  if ($v | type) == "array" then
                    $v | map(if type == "object" then . else {name: .} end)
                  else
                    [{name: $v}]
                  end
                )}}
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

# Warn about fields that could not be applied (missing from page schema or read-only)
skipped=$(jq -rn --argjson updates "$UPDATES_JSON" --argjson pageSchema "$page_resp" '
  [ $updates | keys[]
    | select(. as $k | ($pageSchema.properties[$k].type // "") as $t
        | $t == "" or ($t | IN("created_time", "last_edited_time", "created_by", "last_edited_by", "formula", "rollup", "unique_id", "button", "people", "files", "relation")))
  ] | join(", ")
')
if [ -n "$skipped" ]; then
  echo "Warning: skipped fields (missing from page or read-only): $skipped" >&2
fi

if [ "$(echo "$update_payload" | jq '.properties | length')" -eq 0 ]; then
  echo "Error: no updatable properties in payload; nothing to update." >&2
  exit 1
fi

update_resp=$(notion_api PATCH "pages/$PAGE_ID" "$update_payload")
if echo "$update_resp" | jq -e '.error' > /dev/null; then
  echo "$update_resp" | jq -r '.error.message // .error' >&2
  exit 1
fi
echo "Page updated: $PAGE_ID"
echo "$update_resp" | jq '.'
