#!/bin/bash
# claude/loop.sh - The Stigwheel Loop

MODE="${1:-build}"
MAX="${2:-50}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PROMPT="$SCRIPT_DIR/PROMPT_${MODE}.md"

if [ ! -f "$PROMPT" ]; then
  echo "Error: Prompt file not found: $PROMPT"
  echo "Usage: ./claude/loop.sh [plan|build] [max_iterations]"
  exit 1
fi

echo "Stigwheel Loop - Mode: $MODE, Max: $MAX iterations"

for i in $(seq 1 $MAX); do
  echo ""
  echo "════════════════════════════════════════════════════"
  echo "  Iteration $i of $MAX ($MODE mode)"
  echo "════════════════════════════════════════════════════"

  cd "$PROJECT_ROOT" && claude --dangerously-skip-permissions --print < "$PROMPT"

  echo ""
  echo "Iteration $i complete. Continuing in 2s..."
  sleep 2
done
