# coding-with-agents

My personal framework for using agentic coding tools as a cybersecurity data scientist. Captures the skills/templates/process I follow so I'm not just vibin' it every time.

## Layout

```
coding-with-agents/
└── skills/                          # version-controlled skills (source of truth)
    ├── spec/                        # interrogate idea → spec.md
    ├── tasks/                       # decompose spec → tasks.md
    ├── implement/                   # pick task → build → close loop (CHANGELOG, docs)
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

Orphan work (stuff like "let's try this existing thing with different config", "update pandas", "fix this tiny tiny bug") goes through `/todo`, which drops the entry into root `TODO.md`. Those entries get picked up later via `/implement`, same close-loop.

## Hygiene

Sits alongside the build pipeline, runs on a cadence rather than per-change:

- `/doc-audit` scans the repo for stale or missing docs (README drift, runbook drift, missing/wrong docstrings), shows findings with proposed fixes for approval, applies the ones you OK, and prepends a single summary entry to `CHANGELOG.md`. Specs are out of scope (`/implement`'s close-loop handles those). Run weekly/monthly or after big refactors.
