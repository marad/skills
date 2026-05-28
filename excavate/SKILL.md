---
name: excavate
description: Top-down, layer-by-layer feature development. Guides the user through annotated module diagram → signatures-only stubs → signature-fit review → tests → bodies. Artifacts live in the repo, not in chat. Use when the user has notes/ideas for a new feature, module, or system and wants to design it rigorously before implementing. Trigger phrases - "excavate", "let's design X", "start a new feature using excavation", "top-down design for X".
metadata:
  approach: top-down-stub-first
  audience: experienced-developers
---

# Excavate — Layered Top-Down Feature Development

A disciplined flow for designing and implementing non-trivial features with AI assistance. Each layer produces a **verifiable artifact in the repo** that constrains the next layer, so the AI can't drift and the human keeps architectural control.

## Core Principles

1. **Artifacts in the repo, not in chat.** Diagram, stubs, tests, bodies — all committed. Chat context evaporates; the repo persists.
2. **Each layer must be reviewed before moving on.** No skipping ahead "to see if it works."
3. **No walking skeleton.** Do NOT build a thin end-to-end path first — it biases the excavation toward whatever shape you picked first. Design top-down from the diagram.
4. **Signatures are the contract.** Once locked, bodies become parallelizable and low-risk.
5. **Tests before bodies.** Committed first, written by a separate subagent so the test-writer cannot rationalize the implementer's mistakes. See *Cold-context subagents* below.
6. **Push back, don't just generate.** At every layer, the agent should challenge weak choices rather than confidently produce plausible-looking output.
7. **Phases exist to enable regeneration, not to satisfy ceremony.** This is the central mechanic of the skill. LLM first drafts commit to framings, names, decompositions, and structures that propagate forward and bias every later phase. Each phase boundary is a chance to **re-read your own output as if a stranger wrote it** and ask: *"if I were generating this now, from scratch, would I produce the same thing?"* If no, **regenerate the relevant part, do not patch it.** The cost of rewriting an artifact at its phase boundary is low; the cost of carrying a suboptimal framing through three more phases is high. A phase that produced an artifact but did not exploit this re-read-and-reconsider opportunity has wasted the phase.
8. **Use cold-context subagents for steps that require independence from the design session.** "Read this fresh," "find composition bugs," "write tests against the contract" all suffer when done by the agent that just produced the thing. Spawn a subagent via the `Agent` tool instead of running these in the design conversation. See *Cold-context subagents* below.

## Cold-context subagents

Several steps of this flow explicitly require **a reader who has not seen the design conversation**. The Agent tool gives the main agent that primitive directly — do not ask the user to fork a new conversation. Spawn a subagent.

A correctly-briefed subagent for these steps:

- Receives **only the artifact + the task**. No design rationale, no discussion of alternatives considered, no "I think this is probably right but…" hedging. Those things bias the subagent toward the same framing.
- Receives an **adversarial mandate**. The subagent is told its job is to find problems / write hostile tests / read with suspicion, not to confirm.
- Returns a **structured report or a concrete artifact** (a file path, a patch, a list of flags) that the main agent then integrates.

Subagent types to use:
- `Explore` for "find every place X is used / referenced" within a phase.
- `general-purpose` for write-the-tests, fresh-read review, signature-fit trace.

Subagents are used in: Phase 3 (signature-fit review), Phase 4 (writing tests), and Self-Review Gate Round 1 (fresh re-read). They are optional but recommended in Phase 1 critique. Specific prompts are given in each phase's section.

## Self-Review Gate (run at the end of every phase)

**Purpose:** exploit the phase boundary as a regeneration opportunity. Re-read your own output, decide whether a from-scratch second draft would be materially better, and **regenerate (not patch) the parts where the answer is yes.** A self-review that only produces a checkmark has wasted the phase.

Run in three rounds, in order. Write the findings + actions into a "Self-Review" section in the phase artifact (or chat if there is no artifact). Vague "looks good" reviews are forbidden — name what was checked and what was changed (or explicitly why nothing changed).

### Round 1 — Re-read fresh (via cold-context subagent)

The whole point of Round 1 is to read the artifact as if a stranger wrote it. The agent that just produced it cannot honestly do that — its context is saturated with the design rationale that the artifact is supposed to encode. **Spawn a subagent.**

Use the `Agent` tool with `subagent_type: "general-purpose"` and a prompt that gives the subagent **only the artifact path and the cold-read mandate** — no rationale, no "I think this might be off in section X" hints, no summary of decisions. The subagent must arrive at its own flags.

Prompt template:

> Read `<path-to-artifact>` end-to-end as a fresh reader who has never seen this design. Report (under 300 words):
> 1. Names you had to mentally translate or that felt off.
> 2. Sections where you lost the thread or had to re-read.
> 3. Claims that *sound* right but you cannot defend in one sentence after the read.
> 4. Inconsistencies — anything described one way in section A and a different way in section B.
> 5. Anything that feels like leftover scaffolding from an earlier framing.
>
> Do NOT propose fixes. Do NOT confirm what's good. Only flag.

The main agent receives the report and uses it as input to Round 2.

(If for some reason a subagent is unavailable, the main agent must do the cold read itself — but flag explicitly that this is degraded mode, since context contamination is unavoidable.)

### Round 2 — Reconsider and regenerate

For each Round 1 finding (and for the artifact as a whole), ask: *if I were generating this fresh right now, knowing what the rest of the artifact says, would I produce the same thing?*

Specifically reconsider:
- **Decomposition.** Are the module / function / type boundaries in the right places? Would a different split make the rest of the design fall out more naturally?
- **Names.** Would a fresh reader understand each name without context? Rename liberally — renames are cheap at this phase, expensive once tests and bodies depend on them.
- **Abstraction level.** Too high (everything is a `Service` / `Handler` / `Manager`)? Too low (leaking implementation detail into the signature)?
- **Framing.** Is the artifact structured around the *actual* problem, or around the first framing that came to mind?

**When a part would be materially better regenerated: regenerate it.** Rewrite the section from scratch with the new framing. Do not paste-and-edit — that preserves the autoregressive bias you are trying to escape. If multiple framings seem viable, draft the alternative briefly and compare; pick deliberately.

If no regeneration is warranted, say so and state which alternatives you considered and rejected. "Reconsidered X vs Y, kept X because Z" is acceptable; silence is not.

### Round 3 — Simplify

Now (and only now, on the version produced by Round 2) run the subtraction pass:

1. **Can this be simplified without losing required functionality?** Modules that wrap one call from another, types with one implementation and one caller, options no acceptance criterion needs, indirection with <3 uses, abstractions added for hypothetical futures.
2. **Is anything overcomplicated relative to what the spec asks?** Flag anything solving a more general problem than required. Flag premature optimization, premature concurrency, premature plugin systems.
3. **Anything likely slow or resource-heavy where it matters?** O(n²) over realistic inputs, repeated I/O in loops, loading whole datasets where streaming would do, sync calls on latency-sensitive paths. Only flag if the spec implies it matters.

Apply trivial fixes directly; escalate non-trivial ones before user sign-off.

### Discipline rule

A phase artifact is **not ready** until Self-Review has run all three rounds and the output reflects the result. If Rounds 1 and 2 produced no regeneration, the agent must state explicitly what alternatives were considered. "Self-review found nothing" with no specifics is treated as the self-review not having been done.

## When To Use

The user has notes, a rough idea, or a feature request, and wants to design it rigorously before writing code. Especially valuable when:
- The feature touches >3 modules or crosses process/service boundaries
- State, concurrency, or error semantics are non-trivial
- Multiple sessions or contributors will work on it
- The user has explicitly asked for "excavation" / top-down / interface-first design

Skip this skill for trivial changes, one-file edits, or hotfixes.

For changes that need design discipline but don't justify the full flow — roughly 1–3 files, no new module boundary, single language, fits in one head — use [[chisel]] instead. If you start excavate and Phase 0 reveals the change is chisel-scale, **suggest the switch** rather than pushing through the full ceremony.

## Phase 0 — Intake

### 0a. Read and internalize the notes

Read everything the user pointed at. Do NOT start sketching anything until you have. If the notes are vague on **goal / non-goals / acceptance criteria**, surface that gap and ask the user to clarify before going further. A vague spec produces a vague diagram.

### 0b. Enumerate unknowns, classify them, surface them

After reading, produce a short list of everything the notes do *not* pin down that could affect design. Classify each item:

- **Must decide now (load-bearing)** — choices that change the shape of modules, signatures, or types. The diagram looks fundamentally different depending on the answer.
- **Can defer** — implementation details that the signatures will not depend on.
- **Out of scope** — record and skip.

Common load-bearing items to check for explicitly:

- **Language and runtime** (Python vs Go vs TypeScript … changes everything).
- **Major frameworks/libraries on the critical path** — CLI framework, web framework, ORM, queue, etc. Only the ones whose API shape leaks into your signatures.
- **Error model** — exceptions / Result types / error channels / mixed. Pick one or document where each applies.
- **Sync vs async at boundaries** — which edges are synchronous, which are async (queues, callbacks, futures). Async edges have fundamentally different signatures.
- **Persistence / state shape** — if not specified and the feature has state.
- **Process/deployment model** — single binary, multi-service, library, etc., when it changes the module boundary.

### 0c. Ask the user — do NOT pick silently

For each must-decide-now item, **ask the user**. Use `AskUserQuestion` with 2–4 concrete options and a one-line tradeoff per option. Do not present a single recommendation as if it were settled. You may suggest a preferred option, but the user picks.

Rule of thumb: if changing the answer would force a non-trivial rewrite of the diagram or signatures, it is load-bearing and you must ask. Picking a programming language because the user did not mention one is the canonical violation.

### 0d. What NOT to decide in Phase 0

Phase 0 fixes **decisions**, not **structure**. In particular, do **not** produce:

- A file/directory layout.
- A package/module tree.
- A list of source files.
- A go.mod / pyproject / package.json scaffold.

Physical layout is an artifact that emerges from Phase 2 (signatures-only stubs), and it follows from the *logical* modules in Phase 1. Designing the layout in Phase 0 is premature concretion — it locks in physical structure before the logical decomposition has been validated, and once it is on the page the rest of the design tends to bend to fit it.

### 0e. Output of Phase 0

A short note (can be in chat, or written to `docs/excavation/<feature>/00-decisions.md` if the user wants it persisted): the decisions made, the options considered, and any open questions explicitly deferred. No diagrams, no layouts, no code.

### 0f. Self-review (gate)

Run the *Self-Review Gate* on the decisions: is any decision adding complexity the spec does not need? Any deferred-but-actually-load-bearing item hiding in the list? Resolve before Phase 1.

## Phase 1 — Annotated Module Diagram

**Modules in this phase are logical, not physical.** A module is a named responsibility with a boundary. It is NOT a file, a package, a directory, or a class yet. Resist the urge to write paths or file extensions. The mapping from logical modules to physical files happens in Phase 2, and is usually obvious once the signatures exist.

Produce `docs/excavation/<feature>/01-architecture.md` containing:

- **Goal & non-goals** (3–6 bullets, lifted from the user's notes after clarification).
- **Module list** — each module with a one-line responsibility. Names describe what the module *is*, not where it lives.
- **Diagram** — Mermaid `graph` or `flowchart`. Boxes are logical modules; arrows are dependencies/calls.
- **Edge annotation table** — one row per arrow:

  | From | To | Payload (type) | Sync/Async | Failure owner | Retry policy |
  |------|----|----|----|----|----|

  Every arrow MUST have a row. If you can't fill a cell, that's a design hole — flag it.

- **State ownership** — for each piece of mutable state, which module owns it, and what the transaction/consistency boundary is.
- **Open questions** — anything you couldn't resolve from notes.

### How the agent should behave in this phase

- Propose a first cut, then **immediately critique it** — what's hand-wavy, what arrow lacks a clear failure owner, where state ownership is muddy.
- Ask the user to react to specific concrete choices, not "does this look good?".
- Iterate until the edge table has no empty cells and open questions are either resolved or explicitly accepted as deferred.
- **Optional but recommended:** after the first cut is on the page, spawn a `general-purpose` subagent with only the architecture doc and ask it to attack the diagram (empty edge cells, fuzzy state ownership, modules that look like nouns rather than responsibilities). The main agent integrates findings before the Self-Review Gate.

### Self-review (gate)

Append a **Self-Review** section to `01-architecture.md` answering the three gate questions. Look especially for: modules that only forward calls, edges whose only purpose is "for symmetry," state ownership split across modules where one would do, fan-out patterns that imply N+1 I/O downstream. Resolve or escalate before user sign-off.

**Do not proceed to phase 2 until the user has read and signed off on this file.**

## Phase 2 — Signatures Only

Create real source files in the actual project layout (not in `docs/`). Each file contains:

- Module/namespace/package declaration as appropriate for the language.
- Type definitions for payloads crossing module boundaries (from the edge table).
- Public function/method/class signatures with **types, parameter names, return types, and error/result types — but no bodies**. Use the language's idiomatic stub (`raise NotImplementedError`, `throw new Error("stub")`, `todo!()`, `unimplemented`, `pass`, etc.).
- Brief docstring/comment on each signature: one line on intent, plus pre/post-conditions if non-obvious.

Constraints:
- **The project must compile / type-check after this phase.** That's the verification gate.
- No bodies. No "just a quick implementation for this trivial one." None.
- Signatures must reflect the error model and sync/async choices from phase 0.

### How the agent should behave

- Generate stubs module by module, smallest/leafmost first.
- After each module, run the type-checker / compiler / linter.
- If a signature feels awkward, surface it now — awkward signatures are almost always a sign the diagram is wrong. Go back to phase 1 rather than papering over it.

### Self-review (gate)

Once stubs compile, run the *Self-Review Gate* on the signatures. Specifically check for:
- Parameters that no caller would ever supply (or always supplies the same value).
- Return types richer than any caller actually uses.
- Optional/nullable params that should be two separate functions, or vice versa.
- Generic / parameterized signatures with one concrete use.
- Helper functions exported that nobody outside the module calls.

Write the findings as a short comment block at the top of an `EXCAVATE_NOTES` file in the source tree or in a brief follow-up chat message. Apply trivial simplifications directly; escalate non-trivial ones to the user before Phase 3.

## Phase 3 — Signature-Fit Review

This phase **runs in a cold-context subagent** by default. The main agent just wrote the signatures; asking it to find composition bugs in its own work is asking for self-confirmation. Spawn a `general-purpose` subagent.

Subagent brief:

> Read the stubs under `<source-tree>` and the architecture doc at `docs/excavation/<feature>/01-architecture.md`. You are doing an adversarial signature-fit review.
>
> Pick **3–5 representative user scenarios** (including at least one error case) and, for each:
> 1. Name the scenario.
> 2. Trace the call chain through the actual signatures, `file:function` step by step.
> 3. At every boundary, write the value passed in terms of the actual declared types.
> 4. Flag any data being unpacked/repacked unnecessarily, any signature forcing awkward adaptation, any error with no clear handler.
>
> Be hostile to the design. Red flags to specifically hunt for: pass-through layers, optional params hiding a branching decision, "God" types everything passes around, errors silently swallowed at the wrong layer, async boundaries that secretly assume sync.
>
> Write your trace + findings to `docs/excavation/<feature>/03-signature-fit.md`. Do NOT propose fixes — describe the problems precisely so the main agent can address them.

The main agent reads the report and either fixes (returning to Phase 2 or 1) or escalates to the user. Document the fix and the reason in the same file before user sign-off.

### Self-review (gate)

Append a **Self-Review** section to `03-signature-fit.md`. Beyond the three gate questions, specifically ask: across the 3–5 traces, which steps were pure pass-through? If two adjacent layers always do the same thing in sequence, one of them is probably redundant. Also flag traces where the same data is fetched twice or the same I/O is hit on every step. Resolve before user sign-off.

**Do not proceed until the user has signed off on this file.**

## Phase 4 — Tests Before Bodies

This phase **runs in a cold-context subagent** by default. Same reason as Phase 3: the main agent will implement the bodies; if it also writes the tests, the tests will encode the implementer's mental model rather than the contract, and the "edit the test to match the broken code" failure mode becomes available. Spawn a `general-purpose` subagent.

Subagent brief:

> Read the stubs under `<source-tree>`, the architecture doc at `docs/excavation/<feature>/01-architecture.md`, and the signature-fit doc at `docs/excavation/<feature>/03-signature-fit.md`. Write tests against the **contract**, not against any specific implementation.
>
> Requirements:
> - Tests must compile and run. They will fail (bodies are stubs) — that's correct.
> - Cover the scenarios from `03-signature-fit.md` plus per-module unit cases.
> - Tests assert observable behavior described in signature docstrings and scenarios. They MUST NOT encode implementation details (no asserting on private state, on internal call order, on temp file names, etc.).
> - Commit the tests in their own commit before returning.
>
> If a scenario from `03-signature-fit.md` cannot be expressed as a test against the current signatures, that is a signal the signatures are wrong. Report it; do not paper over it.

The main agent verifies the commit landed and reviews the tests for the smells listed in the self-review section below. The implementer (main agent in Phase 5) **must not edit the test commit** when implementing bodies — if a test is wrong, that's a signature problem and Phase 3/2 reopens.

### Self-review (gate)

Run the *Self-Review Gate* on the test suite before committing. Specifically:
- Are any tests asserting implementation details rather than observable behavior?
- Are any tests duplicates of each other in different framings?
- Is any setup/fixture code more complex than the system under test? That's a smell.
- Are there obvious missing cases (error paths, boundary values) implied by signatures or Phase 3 scenarios?

Apply trivial fixes; escalate substantive gaps to the user.

## Phase 5 — Bodies

Fill in implementations, module by module. Because signatures and tests are locked:
- Each module is independently implementable.
- Work can be parallelized across sessions/agents.
- "Done" is unambiguous: tests pass, type-checker clean.

### How the agent should behave

- Implement leafmost (no-internal-dependencies) modules first.
- After each module: run its tests, then the full suite.
- If implementation reveals a signature is wrong, **stop**. Do not silently change the signature. Go back, update the diagram + signatures + tests deliberately, re-review, then continue.
- Flag any method up front that needs real design work (concurrency, ordering, tricky domain logic) — those are not "just filling in bodies."

### Self-review (gate, per module)

After each module's tests pass, run the *Self-Review Gate* on the implementation **before** moving to the next module:
- Can the body be shorter without losing clarity or correctness? (Removing dead branches, collapsing repeated logic, dropping defensive checks for impossible states.)
- Any premature caching, premature parallelism, premature batching not justified by a measured need or stated spec requirement? Remove it.
- Any hot loop doing repeated allocations, I/O, or expensive lookups that could be hoisted?
- Any helper that exists only because the main function got long? If the main function is now clear, inline the helper.

Apply trivial simplifications directly; surface anything that would change observable behavior or test expectations to the user.

## Phase 6 — Closeout

- Ensure all artifacts are committed: `01-architecture.md`, stubs, `03-signature-fit.md`, tests, bodies.
- Update or create a short `README` in `docs/excavation/<feature>/` linking to all artifacts.
- Note any deferred open questions in the architecture doc so future sessions can pick them up.

## Anti-Patterns To Refuse

- **Silently picking a load-bearing decision the user did not state.** Language, framework, error model, sync/async — if the notes are silent and the answer changes the design, ASK. Presenting a reasonable default as if it were settled is the canonical failure. The user wants an excavation, not a fait accompli.
- **Designing the physical layout before signatures exist.** No file trees, no package trees, no scaffolding in Phase 0 or Phase 1. Layout is an artifact of Phase 2 and follows from logical modules, not the other way around. Putting a directory tree on the page in Phase 0/1 anchors the rest of the design to it.
- "Let's just sketch a working version first to see if it makes sense." → No. That's a walking skeleton; it biases the design. Excavate top-down.
- "Skip the diagram, jump to signatures." → No, unless the feature is truly trivial — in which case this skill is the wrong tool.
- "I'll add bodies to a couple of easy ones while we design." → No. Layer discipline is the whole point.
- "Just edit the test, the implementation is fine." → No. Either the implementation is wrong, or the test was wrong from the start (in which case admit it explicitly, update from phase 3, and re-commit).

## Conversation Style

- Treat the user as an experienced engineer. Skip basics.
- Be terse. Concrete proposals + concrete critiques beat paragraphs of explanation.
- At each phase boundary, explicitly state: "Phase N artifact is ready at `<path>`. Review and confirm before phase N+1."
- Push back on weak choices. The user explicitly wants an excavation, not a yes-machine.
