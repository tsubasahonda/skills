#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAPHQL="${SCRIPT_DIR}/linear_graphql.sh"

TEAM_ID=""
PROJECT_ID=""
ISSUES_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --project-id)
      PROJECT_ID="$2"
      shift 2
      ;;
    --file)
      ISSUES_FILE="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${TEAM_ID}" || -z "${PROJECT_ID}" || -z "${ISSUES_FILE}" ]]; then
  echo "usage: $0 --team-id <id> --project-id <id> --file <issues.json>" >&2
  exit 1
fi

if [[ ! -f "${ISSUES_FILE}" ]]; then
  echo "file not found: ${ISSUES_FILE}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

MUTATION='mutation($input: IssueCreateInput!){ issueCreate(input:$input){ success issue { id identifier title url } } }'

jq -c '.[]' "${ISSUES_FILE}" | while IFS= read -r issue; do
  title="$(jq -r '.title' <<<"${issue}")"
  description="$(jq -r '.description // ""' <<<"${issue}")"
  payload_vars="$(jq -n \
    --arg teamId "${TEAM_ID}" \
    --arg projectId "${PROJECT_ID}" \
    --arg title "${title}" \
    --arg description "${description}" \
    '{input:{teamId:$teamId,projectId:$projectId,title:$title,description:$description}}')"

  response="$("${GRAPHQL}" "${MUTATION}" "${payload_vars}")"
  success="$(jq -r '.data.issueCreate.success // false' <<<"${response}")"
  if [[ "${success}" != "true" ]]; then
    echo "${response}" >&2
    echo "failed to create issue: ${title}" >&2
    exit 1
  fi

  jq -r '.data.issueCreate.issue | [.identifier,.title,.url] | @tsv' <<<"${response}"
done
