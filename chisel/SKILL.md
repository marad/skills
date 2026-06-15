---
name: chisel
description: Lightweight design-before-implement flow for small changes — the compressed cousin of /excavate. Same discipline (no silent load-bearing decisions, contracts before bodies, tests before implementation, self-review) but no formal artifacts and no multi-phase sign-off. Use for changes that fit in roughly 1–3 files, touch no new modules or process boundaries, and fit in one head. Trigger phrases - "chisel", "small change but do it properly", "quick design pass", "/chisel".
metadata:
  approach: lightweight-stub-first
  audience: experienced-developers
  related: excavate
---

# Chisel — Lightweight Design-Before-Implement

The minimum viable version of [[excavate]]. Same principles, compressed: no diagram artifact, no `docs/excavation/` directory, no multi-phase sign-off gates, no separate-session tests. The whole flow lives in chat + commits.

## When to Use Chisel vs Excavate vs Neither

| Use **chisel** when | Use **/excavate** when | Use **neither** when |
|---|---|---|
| 1–3 files changed | >3 files, or new module/service | Typo, rename, dep bump |
| No new module boundary | New cross-process boundary | Single-line fix |
| No new persistent state shape | New state, schema, or migration | Pure refactor with no behavior change |
| Single language/runtime | Multi-language or multi-service | Generated code edit |
| Whole change fits in one head | Multiple sessions / contributors | One-off script |

If you're not sure which to use, **ask the user** with `AskUserQuestion`. Do not silently upgrade or downgrade.

If the change is genuinely trivial (one of the rightmost-column items), just do it. Don't perform chisel theater on a typo fix.

## Core Principles (inherited, not weakened)

1. **No silent load-bearing decisions.** If the change requires picking a library, an error-handling style, a sync/async boundary, or any choice that would force a meaningful rewrite to change later — **ask**. Smallness of the change does not relax this.
2. **Contracts before bodies.** Even at one-function scope, state the signature and the behavior first, then write the body.
3. **Tests before bodies.** One or two tests, committed before the implementation. No separate session required at this scope.
4. **Step boundaries exist to enable regeneration, not to satisfy ceremony.** This is the *point* of the flow. LLM first drafts commit to names, framings, and structures that bias everything downstream. Each step boundary is a chance to re-read your own output fresh and ask: *"if I were writing this now, from scratch, would I produce the same thing?"* If no, **rewrite, don't patch.** A step that produced output but did not exploit this re-read opportunity has wasted the step.
5. **Stay in scope.** No "while I'm here" refactors. If you spot something, write it down for the user, don't do it.

## The Flow

### Step 1 — Frame (chat, ~3 bullets, no files written)

State in chat:

- **What changes**, user-visible, one sentence.
- **What it touches** — file paths or function names that will be edited or added.
- **Unknowns** — anything the user has not pinned down that affects the diff shape.

For each unknown, decide: load-bearing (would change the shape of the diff) or not. Load-bearing ones go to `AskUserQuestion` with 2–4 concrete options. The same rule as `/excavate`: picking a library or error style because the user did not mention one is the canonical violation.

If the framing reveals the change is bigger than chisel-scale, **stop and suggest `/excavate`** instead of muddling through.

### Step 2 — Sketch (chat, signatures-only)

Write out the contract change inline in chat:

- New or modified function/method signatures with types.
- New types if any.
- Error cases — what's raised/returned and where it's caught.
- Brief: 5–15 lines of pseudocode-or-real-syntax. No bodies.

Then **trace it once**: one happy path + one error path, in your head, narrated as 3–5 lines of "input → call → result." If anything feels awkward, surface it before writing code — awkward signatures at this scale almost always mean the wrong file is being edited or the wrong abstraction is being touched.

### Step 3 — Tests (commit)

Write the test(s) that capture the behavior change. Commit them in their own commit before any body is written. They should fail — that's correct.

- One or two tests is usually enough at this scope; cover the happy path and the most-important edge case.
- Tests assert observable behavior, not implementation details.
- If you find yourself writing more than ~3 tests, you may be in `/excavate` territory — reconsider.

### Step 4 — Implementation (commit)

Write the bodies. Run the tests + the full suite. If a test fails for an unexpected reason, fix the body — do **not** edit the test to match. If the test was wrong, admit it, revert the test commit, redo step 3.

### Step 5 — Self-Review (before declaring done)

Three quick rounds — the *point* of this step is to spot things your first-pass generation could not. **Regenerate, don't patch**, when a rewrite would be meaningfully better.

**Re-read fresh (via subagent).** "Read as if a stranger wrote it" is something the agent that just wrote it cannot honestly do — its context is saturated with the implementation rationale. Spawn a `general-purpose` subagent with the Agent tool, give it only the diff (e.g. `git diff` output or the changed file paths) and this brief:
> Read the diff as a fresh reader who has never seen this change. Report under 150 words: names that made you pause, lines you had to re-read, anything that *sounds* right but you cannot defend, leftover scaffolding. Do not propose fixes; only flag.

(For trivial chisels — one tiny function, no naming decisions — skipping the subagent is acceptable. Note it in the review if so.)

**Reconsider.** For each flag (and the diff as a whole), ask: *if I wrote this now, from scratch, would I produce the same thing?* Names, decomposition, where the logic lives, whether two functions should be one or one should be two. If a section would be materially better regenerated, **rewrite it from scratch** — do not paste-and-edit. If no rewrite is warranted, name what you considered and rejected. Silence is not acceptable.

**Simplify.** On the (possibly regenerated) diff, answer all three:

1. **Can this be simpler without losing functionality?** — extra params nobody supplies, helper used once, indirection added for a hypothetical future.
2. **Is anything overcomplicated relative to the spec?** — solves more than asked, defensive checks for impossible states, configuration nobody uses.
3. **Anything likely slow or wasteful where it matters?** — repeated I/O in a loop, O(n²) over realistic inputs, redundant allocations on a hot path. Only flag if the surrounding code implies it matters.

Apply trivial fixes directly. Mind the asymmetry: the three questions above are about *removing* excess, but a cheap, low-risk robustness/correctness fix in code you're already touching is **not** gold-plating — apply it, don't rationalize deferring it ("current data is fine"). Bias toward fixing a flagged tiny issue now over leaving it for a reviewer. Report what was checked, what was regenerated, and what changed. "Looks good" is not an acceptable review.

### Output

A brief end-of-turn line: what changed, what's next. If you noted out-of-scope smells during the work, list them so the user can decide whether to schedule follow-ups.

## Anti-Patterns To Refuse

- **"It's small, just pick the library."** — No. The rule about load-bearing decisions does not relax with scope. Picking silently is the same failure mode here as in excavate.
- **"It's small, skip the tests."** — No. Tests-before-bodies is cheap at this scale (often one test) and prevents the "edit test to match buggy code" failure mode.
- **"While I'm here, let me also …"** — No. Scope creep. Note it for the user; don't do it.
- **"This is actually 5 files but let's chisel it."** — No. If framing reveals the change is bigger, switch to `/excavate`. Forcing a big change through chisel skips the artifacts that prevent drift.
- **"Self-review: looks good."** — Not acceptable. State what was checked, even when clean.

## Conversation Style

- Brevity is the whole point of this skill. Use it.
- One paragraph per step, not five.
- Concrete proposals over open-ended questions.
- At the end: one or two sentences on what changed and what's next.
