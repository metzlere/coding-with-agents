# coding-with-agents

My personal framework for using agentic coding tools as a cybersecurity data scientist. Captures the skills/templates/process I follow so I'm not just vibin' it every time.

## Layout

```
coding-with-agents/
├── scripts/
│   └── ralph.sh                     # dumb bash loop: run /implement on tasks.md until empty
└── skills/                          # version-controlled skills (source of truth)
    ├── spec/                        # interrogate idea → spec.md
    ├── tasks/                       # decompose spec → tasks.md
    ├── implement/                   # pick task → build → close loop (CHANGELOG, docs)
    ├── reconcile/                   # review a batch of changes for coherence, fix the drift
    ├── todo/                        # capture ideas/bugs/chores into root TODO.md
    └── doc-audit/                   # scan repo for stale/missing docs, propose + apply fixes
```

## The pipeline

```
idea
  │
  ▼
/spec        →   docs/specs/<name>/spec.md       (interview, design, decisions)
  │
  ▼
/tasks       →   docs/specs/<name>/tasks.md      (atomic checkbox list)
  │
  ▼
/implement   →   builds one task                 (reads spec.md, edits code,
                 + closes loop                    updates README/spec/docstrings,
                 + updates CHANGELOG.md           prepends to CHANGELOG.md,
                 + marks task done                removes line from tasks.md)
  │
  ▼
repeat /implement until tasks.md is empty
```

`scripts/ralph.sh` automates that last step. It's the "Ralph Wiggum" loop, kept dumb on purpose: a bash `while` loop that grabs the next unchecked task from `tasks.md` and runs a fresh `claude -p` process (one `/implement` pass) on it, over and over, until the list is empty. Each iteration is a clean process with no memory; the filesystem (`tasks.md` + `spec.md`) is the only state passed between them. Guards: a max-iterations ceiling and stall detection (an iteration that removes no task line stops the loop). It runs unattended with `--dangerously-skip-permissions`, so it's for when you're comfortable letting it rip.

It's a standalone script, not a skill, on purpose: you point it at a tasks file and let it run. Launch it from a terminal (auto-mode blocks Claude from kicking off skip-permissions loops itself):

```
bash ~/.claude/scripts/ralph.sh docs/specs/<name>/tasks.md [max-iterations]
```

Max-iterations is optional; it defaults to the current unchecked-task count plus a small buffer. Output tees to `docs/specs/<name>/ralph.log`. After a run, ask Claude to read that log for a rollup.

`ralph.sh` doesn't check that the independently-built tasks fit together. That's `/reconcile`: run it after a ralph run (or after a bunch of manual `/implement`s) to review the whole batch of changes for integration breakage and spec drift, and fix what's broken. It catches the cross-task divergence that per-task tests miss. Different from `/code-review` (bugs in a diff) and `/simplify` (style cleanup) — `/reconcile` is specifically about the pieces fitting together.

Orphan work (stuff like "let's try this existing thing with different config", "update pandas", "fix this tiny tiny bug") goes through `/todo`, which drops the entry into root `TODO.md`. Those entries get picked up later via `/implement`, same close-loop.

## Hygiene

Sits alongside the build pipeline, runs on a cadence rather than per-change:

- `/doc-audit` scans the repo for stale or missing docs (README drift, runbook drift, missing/wrong docstrings), shows findings with proposed fixes for approval, applies the ones you OK, and prepends a single summary entry to `CHANGELOG.md`. Specs are out of scope (`/implement`'s close-loop handles those). Run weekly/monthly or after big refactors.
