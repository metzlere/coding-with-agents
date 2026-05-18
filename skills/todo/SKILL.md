---
name: todo
description: Slash command `/todo`. Capture an orphan task (idea, bug, chore) into root `TODO.md` under the right section — Features, Bugs, or Chores. Use whenever the user wants to park something for later: "add a todo", "track this bug", "remind me to refactor", "we should fix this", "park this for later". Use even when the user doesn't say "todo" explicitly — any capture-for-later intent triggers this. Creates `TODO.md` from scratch if missing. Completion is **not** handled here; `/implement` removes the line and prepends to `CHANGELOG.md` as part of its close-loop.
---

# Todo

Capture orphan work — things that don't belong to a `/spec` — into root `TODO.md`. One job: get the idea written down so it doesn't get lost.

Completion is `/implement`'s job. This skill does not touch `CHANGELOG.md` and does not remove lines from `TODO.md`.

## File setup

`TODO.md` lives at the project root. If it doesn't exist, create it with this skeleton before adding the task:

```markdown
# TODO

## Features

## Bugs

## Chores
```

## Steps

1. **Classify the task type:**
   - **Feature** — new functionality (cues: "add", "build", "implement", "support")
   - **Bug** — something broken to fix (cues: "fix", "broken", "doesn't work", "crash", "regression")
   - **Chore** — maintenance, refactors, config, deps (cues: "refactor", "upgrade", "clean up", "switch from", "migrate", "bump")

   If genuinely ambiguous, ask. Don't guess on borderline cases — misfiled chores rot the backlog.

2. **Map to section:**
   - feature → `## Features`
   - bug → `## Bugs`
   - chore → `## Chores`

3. **Append a checkbox** at the end of the matching section:

   ```markdown
   - [ ] <description>
   ```

   Rewrite casual phrasing into something readable later (e.g., "the date thing is broken" → "Fix date parsing in sales data loader").

4. **Confirm:** name the section and the new open-item count.

## Examples

> "add a todo to build clustering analysis for customer segments"
> → Append `- [ ] Build clustering analysis for customer segments` to `## Features`. "Added to Features (3 open)."

> "track this bug — date parsing breaks in the sales loader"
> → Append `- [ ] Fix date parsing in sales data loader` to `## Bugs`. "Added to Bugs (2 open)."

> "we should bump pandas to 2.x at some point"
> → Append `- [ ] Bump pandas to 2.x` to `## Chores`. "Added to Chores (4 open)."

## What this skill does NOT do

- Does not mark tasks done. `/implement` does that as part of its close-loop (removes the line from `TODO.md`, prepends a dated entry to `CHANGELOG.md`).
- Does not write to `CHANGELOG.md`.
- Does not decompose a spec — that's `/tasks`.
