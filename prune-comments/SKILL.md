---
name: prune-comments
description: Prune the comments an agent left behind in a change - paraphrase of the code, cross-references, ticket numbers, positional narration, five lines of docstring above one ternary. Run on a branch before a human reviews it, and right after opening a pull request. Trigger phrases - "prune comments", "wyczyść komentarze", "obetnij komentarze", "/prune-comments".
---

# Prune Comments

An agent writing code narrates. It restates the line below, points at the file it
read on the way, and carries the ticket number that sent it there. A reader gets
nothing from any of it, and the author is the wrong person to notice: the comment
felt useful while the code was being written. So the pass is separate, and it runs
on the branch before anyone reviews it.

## Scope

The comment lines this branch added or touched. Comments that were already there
belong to some other change, and pulling them into this diff makes it about two
things.

```bash
BASE=$(git merge-base HEAD origin/main)   # origin/master, or the PR's base branch
git diff -U0 "$BASE"...HEAD | grep -E '^\+[[:space:]]*(//|#|\*|/\*|"""|--)'
```

Count what comes back. That count is the inventory, and every entry gets a
decision: keep, shorten, delete. Comments sitting at the end of a code line escape
that grep, so read the diff itself as well and add them to the count.

## The test

A comment survives when it states a fact the code cannot: why this order, why two
fields instead of one, what a caller must never do, a limit imposed from outside
the file (an API contract, a runner that deletes the workspace at job end, a config
key nothing reads that still has to load).

Ask what a reader would get wrong without it. When there is no answer, delete it.

## Delete on sight

1. **Paraphrase of the code or the type.** `/** Always present */` above a field
   typed `string`. "Nothing here is structural" where every field is already
   optional.
2. **Cross-references.** "see `WaveOutcome.sha` in `run-progress.ts`",
   "(ADR-0007 §1)", "as described in MODEL.md §6". A comment never sends the
   reader somewhere else.
3. **Ticket numbers and change history.** `(#650)`, "the rule #761 turned on",
   "the two preconditions left after #650". The log holds that.
4. **A fact already written down elsewhere.** The same sentence on the wire type,
   on the model type and in the design doc. One site keeps it.
5. **A test comment that repeats the test name.**
6. **Positional narration.** "at the FIRST point where both halves are known",
   "the line above". The next edit turns it into a lie.
7. **Call-site description in a docstring.** "The two overloads are the two
   callers." That belongs to the callers.
8. **Defence against a hypothetical future editor.** "so nobody pins this to a
   SHA later." Someone with a good reason will do it anyway.

## Volume is its own finding

Five lines of docstring above one ternary go to half a sentence even when every
word of them is true. A surviving fact is worth one line, rarely two. Where a
comment is right about one clause and noise around it, rewrite the clause and drop
the rest.

## Steps

1. Build the inventory and report its size.
2. Decide every entry against the test, then apply the edits.
3. Confirm the pass moved no behaviour: its own diff holds comment lines and blank
   lines only, and the repo's typecheck and test suite stay green.
4. Commit the pass on its own (`chore: prune comments`) and push to the branch.
   Amend instead only while nothing has been pushed yet.
5. Report the net line count and name what survived, so the next reader sees which
   facts were judged invisible from the code.

## Done

Every inventory entry is decided, the suite is green, and the pass is on the
branch.
