# Code Comment Canon

The rule for every agent that writes or edits code — internal or customer-facing, every time. This is the source of truth the `comment-scrub` skill enforces, and a good standard to point any adversarial PR-review process at too.

## The rule

**Default to no comment. Write one only when a competent engineer would be surprised, misled, or stuck without it.**

A comment earns its place ONLY for one of these:

- a non-obvious **why** — a constraint, a trade-off, or the reason the obvious approach was rejected
- a **foot-gun** — a gotcha that will bite the next person who touches this
- an **unidiomatic choice** — code that looks wrong but is right
- a **link** — to the ticket, spec, or source the code came from
- a **TODO** — marking known, deliberate debt

If a comment meets none of those, delete it.

## Never

- Restate the code. (`i += 1  // add one to i`)
- Narrate what the next line does. The code already says it.
- Write a multi-paragraph "why this exists" essay in the source. That is the commit message's job.
- Comment to apologize for unclear code. Fix the code instead.
- Leave a comment longer than the code it describes.
- Leave commented-out code. Git remembers it.

## Two homes for "why"

- **One non-obvious line** of why → a code comment.
- **The full story** — what changed, why, what it fixes, what it was newly visible after → the commit message and PR body.

If you can't say the comment in one clear line, the *code* is probably the problem, not the comment.

## Internal vs customer-facing

The anti-slop rule is identical for *implementation* comments everywhere. The one exception: **public API surfaces** — SDKs, payment/webhook connectors, anything a customer imports — get proper doc-comments (JSDoc / docstrings on exported symbols), because there the comment is the contract. Still no fluff. Just complete: params, returns, behavior, and any gotcha the caller must know.
