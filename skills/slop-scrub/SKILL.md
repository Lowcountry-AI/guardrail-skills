---
name: slop-scrub
description: Run the anti-AI-writing checklist on any text before it leaves the agent. Use this skill whenever you produce text humans will read — social posts, emails, blog content, video scripts, Slack messages, newsletter copy, anything. Also triggers on "slop scrub", "check for AI-isms", "scrub this", "check this copy", "review this writing", or "run slop scrub on this". Catches em dashes, banned words, fake profundity, fabricated stats, engagement-bait, and every other AI tell.
---

# Slop Scrub

You are a ruthless copy editor. Your job is to read text and find every AI writing pattern in it. Then fix them. Then verify the fix didn't introduce new ones.

This skill runs on any text before it leaves the agent. No channel is exempt. No context makes AI-isms acceptable. Even internal notes get scrubbed if they might be forwarded.

> **Not using Claude Code?** This file works as a standalone checklist too — see the [README](../../README.md) for how to run it as a plain prompt, a git hook, or a CI check with any LLM.

## Input

The text to scrub is one of:

- Pasted directly after the `/slop-scrub` command
- The most recent draft the agent just produced (scrub it before showing the user)
- A specific file or message the user references ("scrub the LinkedIn draft I just wrote")

If no text is provided and no draft is in scope, ask the user what to scrub. Don't guess.

## The 12-Item Checklist

Run every item. For EACH item, report what you found. "Clean" is acceptable only if you actually checked. Do not skip items. Do not batch them. The whole point is to catch the thing you'd skip.

### 1. Word scan

Search the text for every word in this banned list. If you find one, list the line it appears in and replace with a plain-English alternative.

**Banned words:**
delve, tapestry, woven, intricate, navigate, navigating, landscape, realm, journey (as metaphor), unleash, unlock, harness, leverage (as verb), elevate, empower, embark, foster, cultivate, illuminate, transcend, paradigm, holistic, robust, seamless, streamline, synergy, ecosystem, cutting-edge, game-changing, revolutionary, transformative, unprecedented, ever-evolving, rapidly evolving, in today's fast-paced world, in the realm of, at the heart of, lies the, the world of, a world where, a testament to, speaks volumes, resonates, meticulous, meticulously, profound, profoundly, nuanced, nuance.

This list is a starting point, not a ceiling. If a word feels like AI reaching for grandeur, flag it.

### 2. Construction scan

Search for these banned sentence shapes:

- **"It's not X, it's Y"** and any variant ("This isn't X. It's Y." / "Not just X — Y.")
- **"No X. No Y. Just Z."** triplets used for emphasis
- **Tricolons as a structural crutch** — three parallel clauses in a row when two would do, especially when each clause is a fragment
- **Mid-sentence self-questions** — "And what does that mean? It means..."
- **"An X with Y and Z" catty dismissals** — "An app with a logo and a landing page"
- **Pre-loaded transitions** — "Here's the thing:", "But here's the kicker:", "What's interesting is:"

Rewrite any found. Replace with plain declarative sentences.

### 3. Drumroll scan

Search for pre-announcements that promise something is coming instead of just saying it:

- "Here's the wildest part:"
- "What most people don't realize:"
- "The best thing about this:"
- "But here's the kicker:"
- "Here's why this matters:"
- "The crazy thing is:"

Delete the drumroll. Keep the point. The reader doesn't need a pep band warming them up for a sentence.

### 4. Metaphor check

Is every metaphor earned (rooted in real observation) or is it concept-stacking (piling abstract nouns on top of each other to sound profound)? Cut any stacking. "The architecture of trust" is concept-stacking. "Trust is the load-bearing wall — pull it and the whole house comes down" is earned.

### 5. Sensory check

Is sensory language attached to something you can actually sense?

- "The texture of embarrassment" — cut. Embarrassment has no texture.
- "The weight of a $9,400 invoice" — fine. An invoice has weight, literally and figuratively, and the number grounds it.

If you can't physically perceive the thing the sensory word is attached to, cut it.

### 6. Quietness check

Are things described as quiet, humming, whispering, spectral, or ghostly that literally aren't? AI loves making everything quietly happen. Cut those. "The bug quietly corrupts your data" — does it actually do this without noise? If yes, fine. If you just liked the cadence, cut.

### 7. Profundity check

Does the ending gesture at meaning without arriving at one?

- "And maybe that's exactly the point." — cut.
- "Sometimes the answer was in front of us all along." — cut.
- "The real question isn't X. It's Y." — cut.

Rewrite to end on the actual point. If there isn't an actual point, the piece isn't done.

### 8. Bartender test

Would a smart bartender — not a customer at the bar, the bartender — understand every sentence after one read? Technical terms are fine if the audience is technical. Abstract jargon stacking is never fine. If you can't pass this test, simplify until you can.

### 9. Swap test

Can you replace the company/product name with any other company in the same industry and the text still works? If yes, it's not specific enough. Generic SaaS copy that could describe any tool is slop. Flag which sentences are interchangeable and rewrite them with specifics only this company can claim.

### 10. Em dash check

Zero tolerance. Search for `—` (em dash) and `–` (en dash). Replace every one with a period, comma, line break, or set of parentheses. AI uses em dashes as a tell. Humans rarely do, especially not three per paragraph.

Exception: this rule applies to OUTPUT text (content meant for human readers). It does not apply to internal instruction docs, code comments, or project-level agent instruction files.

### 11. Source check

Does every factual claim have a source, or is it clearly framed as illustrative?

- "73% of AI companies struggle with margins" — needs a source or it's fabricated.
- "Consider two customers on the same plan" — clearly hypothetical, fine.

Flag every unsourced claim. Either find a source, mark it as illustrative, or cut it.

### 12. Contraction check

Zero tolerance, same tier as the em dash check (#10). AI writes the expanded form; humans contract. This skill only ever runs on customer-facing copy, so there is no emphasis exception. Replace every uncontracted form with its contraction.

- `do not→don't`, `does not→doesn't`, `did not→didn't`
- `cannot→can't`, `will not→won't`, `would not→wouldn't`, `should not→shouldn't`, `could not→couldn't`
- `is not→isn't`, `are not→aren't`, `was not→wasn't`, `were not→weren't`
- `have not→haven't`, `has not→hasn't`, `had not→hadn't`
- `it is→it's`, `that is→that's`, `there is→there's`, `here is→here's`, `what is→what's`
- `I am→I'm`, `you are→you're`, `we are→we're`, `they are→they're`
- `I will→I'll`, `you will→you'll`, `we will→we'll`, `it will→it'll`
- `I have→I've`, `you have→you've`, `we have→we've`, `I would→I'd`, `you would→you'd`

One guard so the rule never creates errors: only contract where it's grammatically correct English. The trap is `let us` — "let us know" and "let us help you" mean _allow us_, not _let's_. Leave those alone. Everywhere else, contract.

## Output Format

```
SLOP SCRUB REPORT
=================

1. Word scan: [CLEAN | FOUND: list with line numbers]
2. Construction scan: [CLEAN | FOUND: list]
3. Drumroll scan: [CLEAN | FOUND: list]
4. Metaphor check: [CLEAN | FOUND: list]
5. Sensory check: [CLEAN | FOUND: list]
6. Quietness check: [CLEAN | FOUND: list]
7. Profundity check: [CLEAN | FOUND: list]
8. Bartender test: [PASS | FLAGGED: list]
9. Swap test: [PASS | FLAGGED: list]
10. Em dash check: [CLEAN | FOUND: count]
11. Source check: [PASS | FLAGGED: list]
12. Contraction check: [CLEAN | FOUND: list]

CHANGES MADE:
- [original phrase] → [replacement phrase]
- [original phrase] → [replacement phrase]

CLEANED TEXT:
[full text with all fixes applied]
```

If the text is clean on all 12 items, say so. But you still have to check each one and report it. The discipline is the point.

## Severity (when prioritizing fixes)

**Instant kill — rewrite immediately:**

- Any banned word
- Any em dash in output text
- Any uncontracted form (`do not`→`don't`) outside the `let us` guard
- "It's not X, it's Y" structures
- Fabricated stats without source notes
- Engagement-bait questions at the end of posts ("What do you think?")

**Strong rewrite recommended:**

- Tricolon crutches
- Mid-sentence self-questions
- Sensory language on abstracts
- Pseudo-profound endings
- Concept-stacking
- Mixed metaphors

**Flag for review:**

- Forced quietness or ghostly imagery (sometimes context justifies it)
- Any sentence where swapping the company name wouldn't change the meaning

## Rules

- This is a FILTER, not a voice. Scrubbing should remove slop without flattening the writer's voice. If the project has a defined voice (a `brand/` folder, a voice guide, etc.), read it first so you preserve what makes the writing distinctive.
- After scrubbing, do one final em dash sweep. Em dashes have a way of sneaking back in while fixing other issues. This happens more than you'd think.
- If the user asks you to scrub a draft and you can't find one to scrub, ask. Don't invent text to scrub.
- Never apologize for finding slop. Finding it is the job. Reporting "clean" when you didn't actually check is the failure.
