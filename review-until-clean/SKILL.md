---
name: review-until-clean
description: Loop /code-review --fix on the current diff until there are no material findings left. Trigger phrases - "review until clean", "/review-until-clean", "poprawiaj aż będzie czysto".
---

# Review Until Clean

Run:

```
/loop rób /code-review --fix tak długo aż nie będzie istotnych rzeczy do naprawienia 
jeśli po kilku rundach zauważysz, że błędy wciąż są podobne to zatrzymaj się i zastanów z czego to wynika - prawdopodobnie trzeba przebudować coś innego niż samo review wskazuje
```

## Two rules that keep the loop from spinning

Learned the hard way on a long review loop (a typeahead feature took 6 rounds, a
multi-select feature 8) — both had long tails because point-fixes kept spawning
the next variant of the *same* problem.

1. **Restructure after 2 rounds of the same class.** Track the root cause / class
   of each round's findings, not just the individual findings. If the same class
   recurs across **two consecutive rounds**, stop applying point-fixes and rework
   the underlying design at its source. (Canonical example: trying to classify
   keyboard keys by modifier flags — each round found one more key the enumeration
   got wrong; the fix was to stop enumerating, not to add the next key.) The loop
   converges when you fix the cause; it spins when you keep patching effects.

2. **Every test added for a fix must be discriminating.** When you add or change a
   test to lock in a fix, confirm it **fails against the pre-fix behavior**
   (mutation mindset) — not merely that it passes now. A test that passes both
   before and after the fix guards nothing and will let the exact regression back
   in. If you can't make it fail on the old code, you're asserting the wrong
   thing (often: asserting a downstream state that is identical either way instead
   of the behavior the fix actually changed).
