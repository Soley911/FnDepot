#!/usr/bin/env bash
set -euo pipefail

SOCKET_PATH="${SOCKET_PATH:-/usr/local/apps/@appdata/fn-scheduler/scheduler.sock}"
TIMEOUT="${TIMEOUT:-8}"

usage() {
  cat <<'EOF'
Usage:
  $0 <api> [data] [method]

Arguments:
  api        API path under /api, e.g. tasks, tasks/batch, health
  data       Optional JSON payload, e.g. '{"action":"stop","task_ids":[1]}'
  method     Optional HTTP method. Default: POST when data is provided, otherwise GET

Environment:
  SOCKET_PATH  Unix socket path (default: /usr/local/apps/@appdata/fn-scheduler/scheduler.sock)
  TIMEOUT      curl max-time in seconds (default: 8)

Examples:
  $0 health
  $0 tasks
  $0 tasks/batch '{"action":"stop","task_ids":[1]}'
  $0 tasks '{"name":"demo","account":"root"}' POST
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

API="${1:-}"
DATA="${2:-}"
METHOD="${3:-}"

if [[ -z ${API} ]]; then
  usage
  exit 1
fi
if [[ -z ${METHOD} ]]; then
  if [[ -n ${DATA} ]]; then
    METHOD="POST"
  else
    METHOD="GET"
  fi
else
  METHOD="$(echo "${METHOD}" | tr '[:lower:]' '[:upper:]')"
fi

if [[ ! -S ${SOCKET_PATH} ]]; then
  echo "socket not found: ${SOCKET_PATH}" >&2
  exit 2
fi

URL="http://unix/api/${API#/}"

if [[ -n ${DATA} ]]; then
  curl_args=(
    -sS
    --max-time "${TIMEOUT}"
    --unix-socket "${SOCKET_PATH}"
    -H 'Content-Type: application/json'
    -X "${METHOD}"
    --data-raw "${DATA}"
    -i
    "${URL}"
  )
else
  curl_args=(
    -sS
    --max-time "${TIMEOUT}"
    --unix-socket "${SOCKET_PATH}"
    -X "${METHOD}"
    -i
    "${URL}"
  )
fi

curl "${curl_args[@]}"
echo
