#!/usr/bin/env bash
#
# ralph.sh — the dumb autonomous loop.
#
# Pulls the next unchecked task from a tasks.md and runs a fresh `claude -p`
# process on it (one /implement pass) every iteration, until the list is empty,
# the max-iterations guard trips, or a task makes no progress. Each iteration is
# a clean process with zero memory; the filesystem (tasks.md + sibling spec.md)
# is the only state passed between iterations.
#
# Usage:
#   bash ~/.claude/scripts/ralph.sh <tasks-file> [max-iterations]
#
#   <tasks-file>       Path to the tasks.md to march through (required).
#   [max-iterations]   Hard ceiling on iterations. Defaults to the current
#                      unchecked-task count + 3.
#
# Runs headless with --dangerously-skip-permissions so iterations can edit
# files, run tests, and update the changelog unattended. Only run it when you're
# comfortable letting it rip. Output is teed to <tasks-dir>/ralph.log.
#
# After it finishes, run /reconcile to check the independently-built tasks
# actually fit together — this loop never checks cross-task coherence.

set -uo pipefail

TASKS="${1:-}"
if [ -z "$TASKS" ]; then
  echo "usage: bash ralph.sh <tasks-file> [max-iterations]" >&2
  exit 1
fi
if [ ! -f "$TASKS" ]; then
  echo "ralph: tasks file not found: $TASKS" >&2
  exit 1
fi

# Default max = current unchecked count + 3 buffer, unless overridden.
unchecked=$(grep -cE '^\s*- \[ \]' "$TASKS")
MAX="${2:-$((unchecked + 3))}"
if ! [[ "$MAX" =~ ^[0-9]+$ ]]; then
  echo "ralph: max-iterations must be a non-negative integer, got: $MAX" >&2
  exit 1
fi

LOG="$(dirname "$TASKS")/ralph.log"
: > "$LOG"

echo "=== Ralph starting — $unchecked task(s), max $MAX iterations ===" | tee -a "$LOG"

i=0
while grep -qE '^\s*- \[ \]' "$TASKS"; do
  i=$((i+1))
  if [ "$i" -gt "$MAX" ]; then
    echo "Ralph: hit max iterations ($MAX). Stopping." | tee -a "$LOG"
    break
  fi

  before=$(grep -cE '^\s*- \[ \]' "$TASKS")
  echo "=== Ralph iteration $i — $before task(s) left ===" | tee -a "$LOG"

  claude -p "You are one iteration of a Ralph loop. Read $TASKS and the sibling spec.md in the same folder. Take ONLY the first unchecked task. Invoke the /implement skill and follow it for exactly that one task: build it, write and run tests, then close the loop (update CHANGELOG.md, update any docs the change made stale, and remove that task's line from $TASKS). Do only that one task — nothing else. If you cannot finish it cleanly (missing info, the spec contradicts itself, tests fail and won't fix cleanly), do NOT guess and do NOT remove the line: print 'BLOCKED: <reason>' and stop." \
    --dangerously-skip-permissions 2>&1 | tee -a "$LOG"

  after=$(grep -cE '^\s*- \[ \]' "$TASKS")
  if [ "$after" -ge "$before" ]; then
    echo "Ralph: no progress this iteration (task likely blocked). Stopping." | tee -a "$LOG"
    break
  fi
done

if ! grep -qE '^\s*- \[ \]' "$TASKS"; then
  echo "Ralph: tasks.md is empty — all done." | tee -a "$LOG"
fi
