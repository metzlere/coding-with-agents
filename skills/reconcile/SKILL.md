---
name: reconcile
description: Slash command `/reconcile`. Reviews a batch of changes built across multiple tasks (a `ralph` run, or several manual `/implement`s) to make sure the independently-built pieces actually fit together, match the spec, and don't diverge — then fixes what's broken. Catches the cross-task drift that per-task tests and the spec anchor miss. **Do not auto-invoke based on conversational cues** — only run when the user explicitly types `/reconcile`. Runs after a `ralph` run or after a run of `/implement`s. Not a bug hunt (that's `/code-review`) or a style pass (that's `/simplify`).
---

# Reconcile

When tasks get built independently — a `ralph` loop, or a bunch of `/implement` passes — each one is correct on its own but nothing checks that they fit together. Two tasks can make different-but-both-passing choices in the gaps the spec didn't pin down: a producer and consumer that disagree on a data shape, two slightly different error-handling styles, duplicate implementations of the same helper, dead code left over from a superseded approach. Per-task tests pass, the spec was the anchor, but drift still accumulates.

This skill's job is to look at the whole batch of changes as one thing, find where the pieces don't line up or wandered off the spec, and fix it. **This skill writes code** — unlike `/code-review`, it doesn't just report, it reconciles.

## Step 1: Scope the change set

Figure out what "the changes" are. Check `git status` and `git log`:

- If `/implement` ran without committing (the usual case — `/implement` doesn't commit), the work is sitting uncommitted in the working tree. Review `git diff` plus any untracked files.
- If commits were made during the run, review the cumulative diff from where the work started: `git diff <base>..HEAD` (base is usually the merge-base with `main`), plus any uncommitted changes on top.

If the scope is ambiguous (long-lived branch, unrelated changes mixed in), ask the user what range to reconcile rather than guessing.

**Read the completed task blocks in `tasks.md`.** `/implement` leaves a `- [x]` block per finished task listing the files it created/edited/deleted (with why) and an Assumes/Provides note. This is your map. The git diff is one flat blob across the whole batch, but the blocks segment it back into per-task chunks with intent, so you know which task touched what and what each one was trying to do. The diff is still ground truth for what actually changed (a task may have touched more than it logged), but the blocks tell you where to look. The **Assumes/Provides** notes are prime drift suspects: if task A says it provides `DataFrame[ts, value]` and task B assumes `[timestamp, val]`, that mismatch is exactly the kind of thing this skill exists to catch.

Then **read the relevant `spec.md`** (or specs). The spec is the intended design — it's what you're checking the cumulative result against. Pay attention to Architecture sketch, Interface, Data shape, and Key decisions.

## Step 2: Review for coherence

Look across the whole change set for the stuff that only shows up when you see all the tasks together:

- **Integration** — do the pieces actually wire up? Imports resolve. Functions are called with the signatures they're defined with. A module that produces data and a module that consumes it agree on the shape. Things one task assumed another would provide actually exist. Cross-check the **Assumes/Provides** notes from each task's block against what the other tasks actually built (and against the code, not just the note, since the note can be stale).
- **Divergence / inconsistency** — duplicate implementations of the same thing built by different tasks, conflicting patterns for the same job, naming or error-handling style that drifted across tasks, config read two different ways.
- **Dead ends** — leftover code from an approach a later task superseded, half-wired stubs, TODOs a task left behind.
- **Spec alignment** — does the cumulative result match `spec.md`'s intent and honor its Key decisions? Flag where the built thing quietly drifted from the design.
- **Tests** — run the **full** suite, not a subset. Cross-task breakage (task 5 broke task 2) surfaces here. If there's an integration test, this is where it earns its keep.

## Step 3: Report findings

Before changing anything, lay out what you found, grouped and ordered by severity:

- **Breaks it** — integration mismatches, failing tests, things that don't actually work together.
- **Diverges** — inconsistencies and drift that work but shouldn't stay (duplicates, conflicting patterns, spec drift).
- **Noise** — dead code, leftover stubs.

For each, one line: what it is, where (`file:line`), and the fix you'd make.

## Step 4: Fix

Apply the fixes. For each one, after changing it, re-run the tests so you don't trade one break for another. If a fix changes behavior, close the loop the same way `/implement` does: update `spec.md`/`README.md`/docstrings if they went stale, and prepend a dated `CHANGELOG.md` entry (`- YYYY-MM-DD: [Fix] reconcile: <what> [<spec-name>]`).

Fix the clear stuff directly. For a **judgment call** — two reasonable designs and picking one means reopening a decision, or a fix that'd touch a lot of surface area — don't guess. Surface it, recommend an option, and let the user decide. Same ethos as the rest of the pipeline: don't guess past a real fork.

## Step 5: Confirm and stop

Tell the user:
- What was reviewed (the range, how many files/tasks).
- What was found and fixed (one line each).
- Test results after the fixes ("full suite passes").
- Anything left for them to decide (the judgment calls from Step 4).
- Any `CHANGELOG.md` entries added.

Then stop.

## What this skill does NOT do

- Does not build new tasks. That's `/implement`. It only reconciles what's already there.
- Does not hunt for general bugs in a single diff — that's `/code-review`. The focus here is cross-task coherence and spec alignment.
- Does not do pure style/simplification cleanup — that's `/simplify`. It fixes drift, not taste.
- Does not commit unless the user asks.
