---
name: explain
description: Explain why code behaves a certain way by tracing the actual code path and citing file:line — never from memory. Use when the user asks how or why something works (e.g. "why does this job time out with no logs", "what's the difference between loadMissing and getKey here", "how does Laravel handle X").
---

# Code-grounded explanation

Answer the *why* by reading the real code, not from general knowledge.

## Trace, don't recall

- Find and read the actual code path involved — your own codebase, vendored framework/library source, config, wherever the behavior really lives.
- Follow the chain to where the behavior is decided. Don't stop at the first plausible layer.
- For framework behavior (e.g. Laravel job timeouts, exception handling, Eloquent semantics, Elasticsearch mapping), read the framework source rather than describing it from memory.

## Ground every claim

- Cite `file:line` for the code that produces the behavior. Quote the decisive lines.
- If the answer depends on a config value, version, or runtime condition, name it and show where it's read.
- If you can't confirm part of the explanation from the code, **say which part is inference** rather than presenting it as fact.

## Answer the question asked

- Explain the mechanism and the *why*, not just the *what*.
- When the user is comparing two things, contrast them concretely with the code that differs.
- Keep it tight — this is an explanation, not a refactor. Don't change code unless asked.
