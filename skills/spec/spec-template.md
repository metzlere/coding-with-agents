# <Spec name>

## Problem
<2–4 sentences. What's missing or broken today? What changes once this exists? For analytics: what question are you trying to answer or what threat are you trying to detect that you can't today?>

## Context
<The lay of the land. Where it runs (laptop, work cluster, scheduled job). Data sources it reads from and their access pattern (file dump, API, database, streaming). Adjacent code or pipelines it connects to. Constraints from the user's setup (work monorepo conventions, available libraries, no internet, etc.). This is the background an implementer needs to make sensible choices.>

## What it does
<Plain-language behavior. Examples of useful framings:
- An analytic computes some signal on some input and emits some output.
- A pipeline ingests something, transforms it, produces something.
- A tool or script accomplishes some task when run.
- A change to existing code shifts behavior in some way for some reason.>

## Interface / integration
<How it's used or where it plugs in. Examples of what to include:
- CLI invocation and args, or how the script is run
- Function signatures for the main entry points
- Files read and written, with formats (CSV columns, JSON shape, parquet schema)
- Where outputs go (local file, S3, database table, alerts channel)
- For changes to existing code: which modules/classes/functions are touched>

## Architecture sketch
<Stay high level. Modules and what each does in a sentence, data flow in a few arrows, key dependencies (pandas, scikit-learn, scapy, whatever). Not a full design — just enough that "implement this" is a defined task. If you're naming classes or designing interfaces, you've gone too deep.>

## File layout
<Anything beyond a couple of files gets a directory tree. Pins down where stuff lives before `/tasks` decomposes the work, so the implementer isn't guessing paths per task. Skip for trivial changes.

Example:

```
project/
├── src/
│   ├── data.py        # loader
│   ├── score.py       # scoring logic
│   └── models.py      # data contract
├── scripts/
│   └── run.py         # entry point
├── tests/
│   └── test_pipeline.py
└── requirements.txt
```
>

## Data shape
<For work involving structured data: the input and output schemas you're committing to. Column names, types, what each represents. If the input is messy, note the cleaning step.>

## Key decisions
<Decisions made during the interview, with rationale. One line each. Capture rejected alternatives where they came up — this prevents the implementer from re-opening settled questions.

Examples:
- *Batch over streaming* — runs once a day; streaming added complexity without value.
- *Single CSV output, no database* — single-shot data fits easily in memory; SQLite considered but rejected as overkill.
- *Pandas over Polars* — rest of user's stack is pandas; speed not a bottleneck.
- *Threshold = 0.8 to start* — tunable; will revisit after first run on real data.>

## Scope
**In:**
- <Things this build will do.>

**Out:**
- <Things explicitly excluded, especially adjacent things you might be tempted to add. "Real-time mode," "web UI," "multi-tenancy" if not needed, etc.>

## Testing approach
<First, check the repo: what testing patterns and conventions already exist? Framework, file layout, fixture style, typical coverage level. Follow those. If this is a new repo with no existing pattern, propose one here and say why it fits.

Then capture, in plain language, what's getting tested, what isn't, and why. Decide this upfront so `/implement` doesn't have to ad-hoc it per task. Things to cover:
- Which behaviors get tested, and at what level (unit, integration, end-to-end).
- What's intentionally skipped, and why (thin glue, covered indirectly, throwaway).
- Fixture/data strategy (synthetic inline, sample files, real data).
- Anything that diverges from the repo's existing test conventions, and why.

Don't prescribe specific test file paths or per-module test plans here. Naming and layout follow whatever convention the repo (or proposed new convention) already uses.>

For trivial changes (a config bump, a one-line fix), this section can be a single line or omitted entirely.

