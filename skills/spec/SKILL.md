---
name: spec
description: Slash command `/spec`. Interview the user about an idea until you both understand what's being built, then write `spec.md` to `docs/specs/<name>/`. Only run when the user explicitly types `/spec`. Downstream: `/tasks`, `/implement`.
---

Interview the user relentlessly about every aspect of the idea until you reach shared understanding. Walk the decision tree, resolving upstream choices before downstream ones. For each question, offer your recommended answer and let the user correct you — turning answering into reviewing a draft is faster than blank-form questions.

Ask one question at a time. Two at most.

If a question can be answered by reading the codebase, read the codebase instead.

## Context for the user

Solo projects, built for the user's own use. The user is a cybersecurity data scientist with intermediate Python — not a software engineer. There are no stakeholders or users beyond them. Bias toward simpler, more readable code.

## When to push back

Push back when something doesn't add up — scope drift, contradictions with earlier answers, or building something that already exists.

## Writing the spec

After the interview, summarize the spec in your own words and confirm before writing. Then write to `docs/specs/<spec-name>/spec.md` (kebab-case). The template at `spec-template.md` in this skill's folder is a menu — use what adds value, omit the rest. Required: **Problem** and **What it does**. Match depth to complexity: a small change is five lines; a full pipeline gets the whole template.

**Testing approach is part of the interview, not an afterthought.** For anything beyond a trivial change, decide upfront what's getting tested, what isn't, and why. Default to whatever testing patterns and conventions already exist in the repo (framework, layout, fixture style); don't reinvent them. For a new repo with no existing pattern, propose one. Stay at the level of *what* and *why*, not "test file X for module Y". This prevents the "implement now, figure out tests later" trap that always becomes test-never. Capture the decision in the **Testing approach** section.

Capture decisions made during the interview (with the *why*) so the implementer doesn't re-litigate them. The interview should resolve unknowns — if you're tempted to write **Open questions**, keep grilling instead.

Stop after `spec.md` is written. Suggest `/tasks` as the next step but don't run it.
