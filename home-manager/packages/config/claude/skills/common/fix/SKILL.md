---
name: fix
description: Diagnose a bug to its root cause, then make the smallest correct in-scope fix with a focused passing test. Use when the user reports a bug, a failing job, an exception, or asks to fix broken behavior.
---

# Root-cause bug fix

Fix the cause, not the symptom — with a tight, in-scope change the user doesn't have to rein in.

## 1. Diagnose the root cause first

Trace the actual code path to the real cause before touching anything. Read the framework/library internals if needed. Don't patch the surface.

## 2. State the plan before implementing

Briefly state: the root cause, the minimal fix, and which file(s) you'll touch. **Wait for a redirect if the approach is wrong** — picking the wrong path first is the most common friction point, and stating intent lets it get caught early. (E.g. don't reach for an old artisan command, a config-driven knob, or a service-provider hook when an inline change in the right class is correct.)

## 3. Make the smallest correct change

Default to a tight, inline fix in the right place. **Avoid unless explicitly asked:**

- config-driven indirection for what should be an inline value
- service-provider / bootstrap placement for logic that belongs in a class
- new model or command methods, or polluting a model to fire behavior
- backtrace-walking or other clever-but-broad mechanisms
- any out-of-scope edits to unrelated files

Match the codebase's existing conventions and idioms.

## 4. Harden the adjacent failure mode

Go one step beyond the immediate symptom where it's cheap and clearly right — e.g. `tryFrom` + skip-and-log for an unhandled enum value, feature-scoped logging — but stay within the bug's blast radius. Don't expand scope.

## 5. Reproduce and test

- Give the reproduction steps for the bug.
- Add or extend a **focused** test that fails before the fix and passes after.
- Run the relevant tests and confirm they pass. Verify the feature actually works — don't assume.
