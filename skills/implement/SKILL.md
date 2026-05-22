---
name: implement
description: Slash command `/implement`. Invoked deliberately by the user when they're ready to build a single task. Reads the parent `spec.md` for context, builds the code, runs and updates tests, then closes the loop — updates `CHANGELOG.md`, removes the task line from `tasks.md` or root `TODO.md`, and updates `spec.md` / `README.md` / docstrings if the change made them stale. **Do not auto-invoke based on conversational cues** — only run when the user explicitly types `/implement`. Upstream: `/spec` writes the design, `/tasks` decomposes it.
---

# Implement

The user is ready to build. Your job is to pick up a single task, build it correctly, and close the loop on docs and the changelog so nothing drifts.

**This skill is the only one that writes implementation code.** `/spec` interviews; `/tasks` decomposes; `/implement` builds. Stay focused on one task at a time.

## Step 1: Identify the task

The user may say:
- "Implement the next task in the dns-anomaly-detector tasks" → first unchecked task in `docs/specs/dns-anomaly-detector/tasks.md`
- "Pick up task 3" → 3rd unchecked in the active spec's tasks.md
- "Build the data loader task" → search by description
- "Do the pandas bump from TODO.md" → orphan task in root `TODO.md`

If ambiguous, list the candidate unchecked tasks and ask. Do not guess.

## Step 2: Read context

**Always read `spec.md` first** if the task lives in a spec folder. The spec is the design intent — without it you'll re-litigate decisions that were already made and probably get them wrong.

Specifically pay attention to:
- **What it does** — the behavior you're implementing
- **Architecture sketch** — module boundaries, where things go
- **Data shape** — schemas you must honor
- **Key decisions** — things already settled; do not re-open
- **Scope (Out)** — adjacent things you're tempted to add but shouldn't

For orphan tasks (root TODO.md), there's no spec to read. Just do the task as described.

**If the task touches unfamiliar existing code**, gather context before editing. Grep for callers of the symbols you're about to change, look for similar patterns elsewhere in the codebase you should match, check related tests and docs. The recurring failure mode this addresses: agent edits in a vacuum and breaks unseen callers. Don't skip this in the work monorepo.

## Step 3: Build

Implement only the current task. Do not start adjacent tasks "while you're in there." If you find a problem in another task while building this one, note it (add to `TODO.md` or flag verbally) — don't fix it inline.

## Step 4: Tests

Tests are mandatory before close-loop. Test-after, not test-first, but non-negotiable for the task to be "done."

- **Follow the repo's existing testing patterns.** Framework, file layout, fixture style, naming: match what's already there. If this is a new repo with no pattern yet, the `spec.md` Testing approach section should have proposed one; use that. Don't introduce a new convention on a whim.
- **New public behavior gets a test.** New module, new function, new endpoint, new transform — has at least one test exercising it.
- **Changed behavior gets its tests updated.** If you changed what a function returns or how it behaves, existing tests are now wrong; fix them or add new ones covering the new behavior.
- **Run the full suite, not just what you touched.** Failures in unrelated tests usually mean your change broke a caller — investigate before continuing.
- **If `spec.md` has a Testing approach section, follow it.** That decision was made upstream; don't re-litigate it here.

If you genuinely don't think a test is worth writing (e.g., a pure config bump, a one-off script you'll throw away, behavior already covered by an existing integration test), say so explicitly and let the user confirm. Default is: write the test.

If tests fail and you can't fix them cleanly, the task is **blocked** — see "What to do when blocked." Do NOT skip tests to ship.

## Step 5: Close the loop

This is the part that prevents the recurring doc-drift pain. Before declaring done, work through every item:

1. **`spec.md`** — does this still describe what the code does, or did the implementation reveal something different from what was spec'd? If different, update the spec.

2. **Documentation** — `README.md` and any other docs in the repo (e.g., `docs/`, runbooks, usage guides). Did this change anything a reader would care about? Setup steps, what the project does, how to run it, behavior of an interface they rely on. Update whatever's stale — don't stop at the README.

3. **Docstrings** — are docstrings on changed functions still accurate? New public functions should have NumPy-style docstrings.

4. **Callers** — for changes to existing code, are there callers that now have stale assumptions? Grep to confirm. Either update them in this task (if trivial) or flag them as new tasks via `/tasks`.

5. **`CHANGELOG.md`** — record what was done. Prepend a dated entry to `CHANGELOG.md` immediately below the header, newest at top:

   ```
   - YYYY-MM-DD: [Type] <description> [<spec-name>]
   ```

   Type is `[Feature]`, `[Fix]`, or `[Chore]`. The trailing `[<spec-name>]` tag is included only for spec-scoped tasks; omit for orphan TODO.md tasks. For orphan tasks, the type comes from which section they were in (`## Features` → `[Feature]`, `## Bugs` → `[Fix]`, `## Chores` → `[Chore]`).

6. **Mark the task done** — remove the entire `- [ ] ...` line from `tasks.md` (or `TODO.md` for orphan tasks). Do not leave a `- [x]` checkbox; the line is gone, the changelog has it now.

   **Also check `TODO.md` for an originating entry.** Specs often grow out of captured TODOs — `TODO.md` is where the user dumps ideas, bugs, and "oh crap I gotta do that" notes, and a spec is frequently the formalization of one of those lines. When the just-finished work fulfills a TODO entry, remove that line too. If the TODO is broader than what was built (only partially addressed), leave it and note progress verbally. Ask if unclear.

## Step 6: Confirm and stop

Tell the user:
- What was built (one line)
- Test results (one line — "3 new tests added, full suite passes")
- What docs were updated (one line — "spec.md, README.md, CHANGELOG.md updated" or whichever)
- Where the task was removed from
- The CHANGELOG entry that was added

Then stop. Do **not** automatically start the next task. The user picks what to do next — they may want to verify, take a break, or change direction.

## What to do when blocked

If the task can't be completed cleanly — missing info, the spec contradicts itself, the data isn't available, an architectural question wasn't actually decided — **do not guess and ship**. Stop, describe the block, and ask. The user will either answer, kick the question back to `/spec` to amend, or split the task. A blocked task stays in `tasks.md` (or `TODO.md`); it does NOT move to the changelog.

## Multiple tasks at once

If the user says "implement tasks 1, 2, and 3" or "do the next two tasks", that's allowed but treat each one as a discrete pass through Steps 1–6. Don't batch-build everything then close the loop once at the end — tests and the close-loop check are per-task. Otherwise you'll forget what each task touched.

## What this skill does NOT do

- Does not run multiple tasks in parallel.
- Does not skip the close-loop. Ever.
