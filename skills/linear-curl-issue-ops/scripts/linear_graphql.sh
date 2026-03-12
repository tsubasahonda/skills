#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 '<graphql_query>' ['<variables_json>']" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

LINEAR_API_KEY="${LINEAR_API_KEY:-}"
if [[ -z "${LINEAR_API_KEY}" ]]; then
  LINEAR_API_KEY="$(security find-generic-password -s "linear-api-key" -w 2>/dev/null || true)"
fi

if [[ -z "${LINEAR_API_KEY}" ]]; then
  echo "LINEAR_API_KEY is not set and keychain item 'linear-api-key' was not found" >&2
  exit 1
fi

QUERY="$1"
if [[ $# -ge 2 ]]; then
  VARS="$2"
else
  VARS="{}"
fi

QUERY_JSON="$(printf '%s' "$QUERY" | jq -Rs .)"
VARS_JSON="$(printf '%s' "$VARS" | jq -c .)"
PAYLOAD="$(printf '{"query":%s,"variables":%s}' "$QUERY_JSON" "$VARS_JSON")"

curl -sS https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: ${LINEAR_API_KEY}" \
  --data "${PAYLOAD}"
