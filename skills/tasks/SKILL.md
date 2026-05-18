---
name: tasks
description: Slash command `/tasks`. Decompose a finished `docs/specs/<name>/spec.md` into an atomic checkbox list at `docs/specs/<name>/tasks.md`. **Do not auto-invoke based on conversational cues** — only run when the user explicitly types `/tasks`. Output is consumed downstream by `/implement`.
---

# Tasks

Decompose a finished spec into an atomic checkbox list a fresh session can pick up one task at a time.

## Steps

1. **Identify the target spec.** Usually `docs/specs/<name>/spec.md`. If the user didn't name one, list available specs and ask. If there's only one in-flight spec, you may proceed and confirm.

2. **Read `spec.md` thoroughly.** Pay attention to: What it does, Architecture sketch, Interface, Data shape, and Scope. These tell you what to build and what NOT to build. If anything is still ambiguous after reading — scope boundaries, file layout, what counts as "done" for a piece — ask the user before decomposing. Don't paper over gaps with guesses.

3. **Decompose into atomic tasks.**

   **What "atomic" means here:** small enough that a single fresh session can pick it up, read `spec.md` for context, finish it cleanly, and close the loop on docs. Roughly: one module, one endpoint, one transform. If a task description starts to feel like its own mini-spec, split it.

   **Tests live inside each task, not as their own line items.** A task to build `src/score.py` includes writing its unit tests. A task to add an endpoint includes its tests. Otherwise you get the "implement now, test later" trap that always becomes test-never. The one exception: a single integration test that spans multiple modules can be its own task (and usually its own phase), since it doesn't naturally belong to any one module's task.

4. **Group tasks into phases.** A phase is a batch of tasks that have no dependencies on each other and can be built together or in parallel. Phases run sequentially — every task in phase N must be possible to start before phase N+1 begins.

   **How to phase:**
   - Foundational stuff first (config files, data contracts, schema/index changes). These usually fit one phase because they're independent declarations the rest of the code reads.
   - Then standalone modules that depend on the foundations but not each other.
   - Then integration tasks that wire those modules together (these often have to be sequential).
   - Then surface layers (UI, scripts, endpoints).
   - Polish / data prep / renames at the end.

   **Stay flexible.** Phase names, count, and shape vary per spec. Use names that fit the work: "Foundations", "Pipeline modules", "Integration", "UI", "Data prep", "Tests" — or something specific to the domain. A small spec might have 2 phases; a big one might have 6. A phase with a single task is fine if that's its natural shape (e.g. one wiring task that nothing else can run alongside). Don't force balance.

   **Sanity check each phase:** if you reordered the tasks within a phase, would anything break? If yes, those tasks belong in different phases.

5. **Write `docs/specs/<name>/tasks.md`** in this format:

   ```markdown
   # Tasks: <spec-name>

   Read `spec.md` in this folder for full context before starting any task. Each task includes its own tests unless explicitly noted.
   Tasks within a phase are independent and can be done in any order or together. Phases run sequentially.

   ## Phase 1: Foundations

   - [ ] Set up project skeleton (src/, scripts/, config/) and `requirements.txt`
   - [ ] Define data contract in `src/models.py` — Pydantic schema for input rows

   ## Phase 2: Pipeline modules

   - [ ] Implement data loader (`src/data.py`) + unit tests — reads input, returns DataFrame
   - [ ] Implement scoring function (`src/score.py`) + unit tests — applies threshold, returns flagged rows

   ## Phase 3: Wiring

   - [ ] Wire entry point (`scripts/run.py`) — loads config, runs loader → scorer → writes CSV

   ## Phase 4: Integration tests

   - [ ] Integration test (`tests/test_pipeline.py`) — feeds sample input through full pipeline, asserts output shape
   ```

   - Phase headers are `## Phase <N>: <short name>`.
   - One checkbox line per task. Each line names the artifact (file or area) and what's done to it.
   - No nested lists, no priorities, no estimates.

6. **Confirm.** Tell the user how many tasks and how many phases were written, and the file path. Suggest `/implement` for the next step (the user can ask for a single task or a whole phase). Stop.

## If `tasks.md` already exists

Ask: overwrite, append new tasks only, or abort. Don't silently overwrite — the user may have edited tasks manually.
