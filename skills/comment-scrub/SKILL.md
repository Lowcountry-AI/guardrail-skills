---
name: comment-scrub
description: Run the code-comment hygiene checklist on a code diff before it's committed. Use this skill whenever you write or edit code — a pipeline stage, an ad-hoc fix, a customer-facing package, anywhere. Also triggers on "comment scrub", "check the comments", "scrub these comments", "comment hygiene", "are these comments earning their place", or "run comment scrub". Catches comments that restate the code, multi-paragraph why-essays, apology comments, commented-out code, and every other comment that hasn't earned its place.
---

# Comment Scrub

You are a ruthless senior engineer reviewing comments. Your job is to read a code diff, find every comment that has not earned its place, and cut or rewrite it. The standard this enforces is the Code Comment Canon (`COMMENTS.md`, bundled alongside this skill). This skill is self-contained — you do not need to open that file to run it.

This runs on any code before it's committed. No code is exempt. "The comment is helpful" is the exact rationalization this skill exists to catch — you are not the judge of that, the checklist is.

> **Not using Claude Code?** This file works as a standalone checklist too — see the [README](../../README.md) for how to run it as a plain prompt, a git hook, or a CI check with any LLM.

## Input

The code to scrub is one of:

- Code pasted directly after the `/comment-scrub` command
- The diff the agent just wrote — scrub it before committing. Run `git diff HEAD` to see every change not yet committed (staged and unstaged together).
- A specific file the user names

If nothing is in scope, ask what to scrub. Don't guess.

**Scope rule: scrub only the comments on lines this change ADDED or MODIFIED.** You are cleaning this diff, not auditing the whole file. If you spot a pre-existing slop comment outside the diff, note it under PRE-EXISTING in the report — do not block on it and do not edit it.

## The checklist

Run every item against each comment in the diff. Report what you found per item. "Clean" counts only if you actually checked. Do not skip items. The whole point is to catch the one you'd wave through.

### 1. Restatement scan
Does the comment say what the code already says? (`i += 1  // increment i`, `// loop over the users` above an obvious loop, `// return the result`.) Cut it.

### 2. Earn-its-place test
For every comment still standing, decide which single justification it meets: non-obvious why / foot-gun / unidiomatic choice / link to ticket-or-source / deliberate TODO. If it meets none, cut it. (Survivors don't need listing in the report; cuts do.)

### 3. Length scan
Is the comment longer than the code it describes — even just 2 lines on a one-line statement? Is any block longer than ~3 lines? Either way it's carrying a commit-message narrative in the wrong place. Keep the one load-bearing line; move the rest to the commit message. Never delete a real constraint — compress it.

### 4. Apology scan
Is the comment compensating for unclear code, a bad name, or a confusing structure? ("// this is hacky but it works", "// not sure why this is needed".) The comment can't be fixed in isolation — fix the code or the name, then delete the comment.

### 5. What-vs-why check
Rewrite any surviving "what" comment into a "why," or cut it. The code is the "what." The comment exists for the "why."

### 6. Banned-shape scan
- Dated narrative blocks ("Why this exists — 2026-..."): the date and the story belong in git, not the source.
- "NOTE:" / "IMPORTANT:" used to shout at no one: keep only if it flags a real foot-gun.
- Commented-out code: delete it. Git remembers.

### 7. Public-API exception
Is this a public or exported symbol in a customer-facing package (an SDK, a payment connector, anything a customer imports)? If so, a proper doc-comment — params, returns, behavior, caller gotchas — is REQUIRED. Don't cut it. Check it's complete and fluff-free instead.

## Output format

```
COMMENT SCRUB REPORT
====================
Scope: [files / diff scrubbed]

1. Restatement scan: [CLEAN | CUT: file:line — comment]
2. Earn-its-place:   [CLEAN | CUT: file:line — comment (met no justification)]
3. Length scan:      [CLEAN | COMPRESSED: file:line — N lines to 1]
4. Apology scan:     [CLEAN | FOUND: file:line — code fix needed]
5. What-vs-why:      [CLEAN | REWROTE: file:line]
6. Banned-shape:     [CLEAN | FOUND: list]
7. Public-API:       [N/A | CHECKED: file:line — complete?]

CHANGES MADE (apply each with Edit):
- file:line  [removed | rewrote | compressed]: <before> → <after, or DELETED>

PRE-EXISTING (not blocking, for the author):
- [none | file:line — note]
```

If every comment is clean, say so — after checking and reporting each item.

## Severity

**Instant cut:**
- Comment that restates the code
- Comment that meets none of the five justifications (earn-its-place failure)
- Commented-out code

**Rewrite or compress:**
- A "what" comment that should be a "why"
- A multi-paragraph or over-long why-essay → compress to the one load-bearing line (never delete a real constraint)
- NOTE / IMPORTANT with no real foot-gun behind it

**Fix the code, then delete the comment:**
- An apology comment — it can't be repaired in isolation; fix the name or the code, then drop it

**Flag, don't auto-cut:**
- A comment that's borderline but might encode real context — surface it, let the author decide
- Any comment outside the lines this diff touched

## Rules

- Scrub only what the diff added or changed. You are cleaning this change, not policing the file's history.
- The narrative goes in the commit message and PR. Never re-add it as a comment "to be safe."
- Public-API doc-comments are the one place where fuller is correct. Don't strip a contract.
- Never delete a comment that encodes a non-obvious constraint just because it's long. Compress it. Don't lose the constraint.
- Reporting "clean" without checking each item is the failure. The discipline is the point.
