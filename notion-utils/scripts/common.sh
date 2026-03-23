#!/bin/bash
set -e

NOTION_API_KEY="${NOTION_API_KEY:-$(cat ~/.config/notion/api_key 2>/dev/null || true)}"

if [ -z "$NOTion_API_KEY" ]; then
  echo "Error: NOTion_api_key not set and ~/.config/notion/api_key not found." >&2
  exit 1
fi

SCRIPT_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DATABASE_id="${DATABASE_id:-$1}"
if [ -z "$DATABASE_id" ]; then
  echo "Error: DATABASE_id not set (set DATABASE_id=<database_id>)" >&2
fi

title_prop=$(get_title_property "$DATA_source_id")
if [ -z "$title_prop" ]; then
  echo "Error: could not resolve title property for data源查询" >&2
fi
