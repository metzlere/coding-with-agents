---
name: doc-audit
description: Slash command `/doc-audit`. Scan the codebase for documentation that's missing, stale, or contradicts the code. Presents findings with proposed fixes for user approval, then applies them in place and logs a single summary entry to `CHANGELOG.md`. Run periodically (weekly, monthly, or after large refactors) as the codebase grows. Do not auto-invoke based on conversational cues; only run when the user explicitly types `/doc-audit`.
---

# Doc Audit

Scan the repo for doc drift and coverage gaps, propose fixes, and apply the ones the user approves. One command, one pass, one CHANGELOG line.

This is hygiene work, not build work. It runs on a cadence, not per-change. `/implement`'s close-loop only catches docs touched by the current change; this catches the drift that accumulates over time (old changes, refactors that didn't update READMEs, docstrings that fell out of sync).

## What to audit

Two passes. Drift first (higher signal), then coverage.

Specs (`docs/specs/<name>/spec.md`) are out of scope. They're design intent, not user-facing documentation, and `/implement`'s close-loop already keeps them in sync with the code it touches. Don't audit them here.

### Drift (docs vs reality)

- `README.md`. Setup steps that don't work, features that don't exist anymore, CLI flags or usage examples that don't match the code.
- Docstrings on public functions. Documented params that no longer exist, return types that changed, behavior described that was removed.
- Other docs (`docs/`, runbooks, usage guides) referencing specific code paths, function names, or flags that no longer exist. Skip anything under `docs/specs/`.

### Coverage (missing docs)

- Public functions or classes lacking docstrings (NumPy-style is the convention).
- Modules or packages that probably need a top-level docstring or README and don't have one.

## Steps

1. **Scope check.** If the user passes a path or glob (e.g., `/doc-audit src/loaders/`), audit only that. Otherwise audit the whole repo.

2. **Scan.** Run drift pass first, then coverage. Be conservative on drift; if you're not sure something is actually contradicting the code, skip it. False positives are worse than missed findings here.

3. **Present findings with proposed fixes.** Group drift before coverage. Number each finding so the user can pick by number. For each one show:
   - File and line.
   - What's wrong, in one line.
   - The proposed fix (the actual replacement text, or "add NumPy-style docstring" for coverage gaps).

   Format:
   ```
   ## Drift (3)
   1. README.md:42
      Issue: install step references removed `setup.py`, repo uses pyproject.toml now.
      Fix: replace `python setup.py install` with `pip install -e .`

   2. src/loaders/sales.py:88
      Issue: `load_sales` docstring lists `region` param but signature no longer has it.
      Fix: remove `region` from Parameters block.

   3. docs/runbooks/ingest.md:14
      Issue: runbook describes a `--retry` flag the CLI no longer accepts.
      Fix: flag for user review (intent unclear: was the flag dropped on purpose?).

   ## Coverage (2)
   4. src/transforms/window.py
      Issue: public function `rolling_iqr` has no docstring.
      Fix: add NumPy-style docstring.

   5. src/loaders/dns.py
      Issue: public class `DNSStreamReader` has no class docstring.
      Fix: add class docstring.
   ```

4. **Ask which to apply.** "Which should I apply? (all / none / numbers like `1,2,4` / range like `1-4`)"

   For findings marked "flag for user review" (cases where it's unclear whether the doc or the code is the source of truth, e.g., a flag that disappeared but might come back), do not auto-apply even on "all". Surface those separately at the end and ask the user how to handle each.

5. **Apply approved fixes.** Edit files in place. For coverage gaps where you're adding a docstring, read the function body first so the docstring is actually accurate (don't fabricate behavior).

6. **Prepend a single CHANGELOG entry.** One header line summarizing the pass, with one sub-bullet per file actually changed:

   ```
   - YYYY-MM-DD: [Doc] doc-audit pass
     - <file>: <one-line description of what changed>
     - <file>: <one-line description of what changed>
   ```

   The sub-bullet description should be specific about *what* changed in that file, not just "drift fix" or "added docstring". Examples:
   - `README.md: replaced setup.py install step with pip install -e .`
   - `src/loaders/sales.py: removed stale region param from load_sales docstring`
   - `src/transforms/window.py: added docstring for rolling_iqr`
   - `src/loaders/dns.py: added class docstring for DNSStreamReader`

   One sub-bullet per file, even if multiple findings touched the same file (combine them into one description). If nothing was applied, skip the CHANGELOG entry entirely.

7. **Confirm and stop.** Tell the user:
   - How many findings were applied vs skipped vs flagged for review.
   - Which files changed.
   - The CHANGELOG entry that was added (or that none was needed).

## What this skill does NOT do

- Does not fix things without showing them to the user first.
- Does not auto-apply fixes flagged for user review (spec drift, ambiguous cases).
- Does not flag stylistic preferences (wording, tone, formatting). Only factual drift and missing coverage.
- Does not write to `tasks.md` or `TODO.md`. Findings are handled in the same run; nothing gets parked.
