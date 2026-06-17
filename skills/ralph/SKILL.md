---
name: ralph
description: Slash command `/ralph`. The dumb autonomous loop. A bash `while` loop that pulls the next unchecked task from a `tasks.md` and runs a fresh `claude -p` process on it (one `/implement` pass) every iteration, until the list is empty, a max-iterations guard trips, or a task makes no progress. Each iteration is a clean process — the filesystem (`tasks.md` + `spec.md`) is the memory. **Do not auto-invoke based on conversational cues** — only run when the user explicitly types `/ralph`. Upstream: `/tasks` writes the list. Wraps: `/implement`. Pair with `/reconcile` afterward to catch cross-task drift.
---

# Ralph

This is the "Ralph Wiggum" loop, kept deliberately dumb. Instead of the user typing `/implement` once per task, `/ralph` runs a bash loop that keeps grabbing the next unchecked task from `tasks.md` and running a brand-new `claude -p` process on it, until the list is empty.

The whole trick is that **each iteration is a fresh process with zero memory**, and the **filesystem is the state**. Every iteration re-reads `tasks.md` and `spec.md` off disk, does one task, removes that task's line, and dies. There's no orchestrator holding context across tasks. Like Ralph, each pass is a clean brain that does one thing and forgets everything. As Geoffrey Huntley put it: "Ralph is a bash loop."

This skill does NOT build code itself. It builds and runs the loop. The actual building happens inside each `claude -p` iteration, which runs `/implement` on one task.

It also does NOT check that the tasks fit together coherently. That's a separate job — run `/reconcile` after the loop finishes to catch cross-task drift and integration breakage.

## Step 1: Set up the run

Figure out three things, then confirm them with the user before kicking off (this runs unattended and spends tokens, so a one-line confirm is worth it):

1. **The `tasks.md` path.** If the user named a spec, use `docs/specs/<name>/tasks.md`. If there's one in-flight spec, use it. If several have unfinished tasks, list them and ask.
2. **Max iterations.** Default to the current number of unchecked tasks plus a small buffer (e.g. tasks + 3). The user can override. This is the guard that stops a runaway loop.
3. **Permissions.** The loop runs headless `claude -p` processes, so they can't stop to ask for permission. They run with `--dangerously-skip-permissions` so they can edit files, run tests, and update the changelog unattended. Call this out plainly so the user knows what they're authorizing. If they're not comfortable with skip-permissions, they should run `/implement` per task instead.

## Step 2: Run the loop

Write the loop to a script and run it. Background it for anything longer than a couple tasks, and tee everything to a log so you can summarize at the end.

```bash
#!/usr/bin/env bash
set -uo pipefail

TASKS="docs/specs/<name>/tasks.md"          # set in Step 1
MAX=10                                        # set in Step 1
LOG="$(dirname "$TASKS")/ralph.log"

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
```

Two guards keep it from spinning forever:
- **Max iterations** — a hard ceiling so a runaway loop can't burn tokens indefinitely.
- **No-progress / stall detection** — if an iteration didn't reduce the unchecked-task count, the task is stuck (blocked, or the process printed `BLOCKED` and left the line in place). The loop stops instead of re-attempting the same task over and over.

Re-reading `tasks.md` every iteration is the point: the previous process removed its own line when it finished, so the file is the single source of truth for what's left. No state is passed between iterations except what's on disk.

## Step 3: Report

When the loop ends, read the log and give the user a clean rollup. Don't dump the whole log:

- **How it ended** — "tasks.md is empty, all done", "hit the max-iterations guard", or "stopped on a stalled/blocked task".
- **What got built** — pull the per-task results out of the log, one line each, in order.
- **The block, if any** — the `BLOCKED:` reason from the last iteration and what's left to do.
- **What's left** — how many unchecked tasks remain in `tasks.md`.
- **Next step** — suggest `/reconcile` to make sure the independently-built tasks actually fit together. This is important: the loop never checked coherence, so a clean run does not mean the pieces wire up correctly.

Then stop.

## What this skill does NOT do

- Does not build code in the main session. Every task runs in its own `claude -p` process.
- Does not hold context across tasks. The filesystem is the only memory.
- Does not check cross-task coherence or integration. Run `/reconcile` for that.
- Does not commit. Changes accumulate in the working tree; the user commits when they're ready.
- Does not retry a blocked task. No progress in an iteration stops the loop.
