#!/usr/bin/env bash
# fetch-ollama-models.sh
# Scrapes the Ollama library via the local FastAPI service and saves the result as JSON.
#
# Usage:
#   ./scripts/fetch-ollama-models.sh [-o|--output <path/to/models.json>]
#
# Options:
#   -o, --output   Output file path (default: ./data/ollama/local/models.json)
#   -h, --help     Show this help message

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
SCRAPE_URL="http://localhost:8000/scrape?url=https://ollama.ai/library"
DEFAULT_OUTPUT="$(pwd)/data/ollama/local/models.json"
OUTPUT_FILE="${DEFAULT_OUTPUT}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
err()  { echo "[ERROR] $*" >&2; }

die() {
  err "$1"
  exit "${2:-1}"
}

require_cmd() {
  command -v "$1" &>/dev/null || die "Required command not found: $1. Please install it and retry."
}

# ---------------------------------------------------------------------------
# Parse CLI arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      [[ -n "${2:-}" ]] || die "Option $1 requires an argument."
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    --)
      shift; break ;;
    -*)
      die "Unknown option: $1. Run with -h for usage." ;;
    *)
      die "Unexpected argument: $1. Run with -h for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
require_cmd curl

if ! command -v jq &>/dev/null; then
  warn "jq not found — output will be saved as-is (no pretty-print)."
  HAS_JQ=false
else
  HAS_JQ=true
fi

log "Checking service availability at localhost:8000 ..."
if ! curl -sf --max-time 5 -o /dev/null "http://localhost:8000/docs" 2>/dev/null; then
  die "Cannot reach http://localhost:8000 — is the service running? (try: make dev)"
fi

# ---------------------------------------------------------------------------
# Ensure output directory exists
# ---------------------------------------------------------------------------
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR" || die "Failed to create output directory: $OUTPUT_DIR"

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

# ---------------------------------------------------------------------------
# Fetch with retries
# ---------------------------------------------------------------------------
log "Scraping Ollama library..."
log "  Endpoint : $SCRAPE_URL"
log "  Output   : $OUTPUT_FILE"

HTTP_STATUS=$(curl -sf \
  --max-time 30 \
  --retry 3 \
  --retry-delay 2 \
  --retry-connrefused \
  -o "$TMP_FILE" \
  -w "%{http_code}" \
  "$SCRAPE_URL" 2>/dev/null) || true

[[ -z "$HTTP_STATUS" ]] && die "curl failed to connect to $SCRAPE_URL."

if [[ "$HTTP_STATUS" -ne 200 ]]; then
  BODY=$(cat "$TMP_FILE" 2>/dev/null || echo "<empty>")
  die "HTTP $HTTP_STATUS from scrape endpoint. Response: $BODY"
fi

# ---------------------------------------------------------------------------
# Validate + save JSON
# ---------------------------------------------------------------------------
if $HAS_JQ; then
  jq empty "$TMP_FILE" 2>/dev/null || die "Response is not valid JSON: $(cat "$TMP_FILE")"
  jq . "$TMP_FILE" > "$OUTPUT_FILE"
else
  if command -v python3 &>/dev/null; then
    python3 -c "import json,sys; json.load(open('$TMP_FILE'))" 2>/dev/null \
      || warn "Saved but response may not be valid JSON."
  fi
  cp "$TMP_FILE" "$OUTPUT_FILE"
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
MODEL_COUNT=0
$HAS_JQ   && MODEL_COUNT=$(jq 'length' "$OUTPUT_FILE" 2>/dev/null || echo 0)
$HAS_JQ   || MODEL_COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTPUT_FILE'))))" 2>/dev/null || echo 0)

log "Done. $MODEL_COUNT model(s) saved to: $OUTPUT_FILE"
