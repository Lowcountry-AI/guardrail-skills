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

## The 13-Item Checklist

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

Check for stiff, over-expanded prose, but do not force contractions into every sentence. AI often avoids contractions even when the surrounding voice uses them. Where a contraction sounds natural for this writer and reader, use it; where the expanded form adds emphasis, fits a formal passage, or matches the author's samples, keep it. Preserve contractions already present when they fit.

Examples of common contractions include `do not` / `don't`, `cannot` / `can't`, `will not` / `won't`, `it is` / `it's`, `we are` / `we're`, and `I have` / `I've`. Check meaning and grammar before changing a form. In particular, `let us know` and `let us help you` mean _allow us_, so do not change them to `let's`.

Flag repeated uncontracted forms when they make conversational copy sound formal or unlike its author. Do not treat an isolated expanded form as an error by itself.

### 13. Staccato check

Look for adjacent runs of two or more sentences where every sentence is short (about 12 words or fewer), declarative, a complete claim on its own, parallel in shape, and unconnected to the next sentence by a word or phrase such as `because`, `so`, `which`, `when`, `but`, or `and`. The run reads like a list of verdicts.

Example to rewrite: "The same request produces a different plan tomorrow. A passing test does not carry forward." Join the claims: "The same request produces a different plan tomorrow, so a passing test doesn't carry forward."

- Three or more qualifying sentences in a row: rewrite the run.
- Two qualifying sentences in a row: flag the run for review. Rewrite it when both sentences also avoid contractions.

Join the claims with a connective that states their relationship, vary sentence length on purpose, or add a concrete example that supports the claim. One short sentence after a longer one can work when the contrast is the point.

Exempt headlines, bullets, calls to action, captions, table cells, and quoted speech from a named person.

## Output Format

```
SLOP SCRUB REPORT
=================

VOICE: [USED: project-root VOICE.md | NOT FOUND: offer to build one from two author-selected pieces]

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
13. Staccato check: [CLEAN | FLAGGED: list]

CHANGES MADE:
- [original phrase] → [replacement phrase]
- [original phrase] → [replacement phrase]

CLEANED TEXT:
[full text with all fixes applied]
```

Check and report all 13 items, even when each one is clean.

## Severity (when prioritizing fixes)

**Instant kill — rewrite immediately:**

- Any banned word
- Any em dash in output text
- "It's not X, it's Y" structures
- Fabricated stats without source notes
- Engagement-bait questions at the end of posts ("What do you think?")

**Strong rewrite recommended:**

- Tricolon crutches
- Staccato runs of three or more qualifying sentences, and two qualifying sentences when both are uncontracted
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
- If a project-root `VOICE.md` exists, read it in full on every run. Use it to calibrate sentence length, directness, vocabulary, and use of `I` versus `we`. Ask: would this author say this sentence aloud to this reader? After scrubbing, compare the result with the samples. If a reader could tell which samples the author wrote but could not recognize the cleaned text as the same author's work, revise the scrub so it preserves the voice.
- A voice sample calibrates style; it never permits a banned item. Never scrub or edit the sample itself. If no project-root `VOICE.md` exists, state that in the report and offer to build one from two short pieces the author selects. Do not invent a voice or write sample pieces on the author's behalf.
- After scrubbing, do one final em dash sweep. Em dashes have a way of sneaking back in while fixing other issues. This happens more than you'd think.
- If the user asks you to scrub a draft and you can't find one to scrub, ask. Don't invent text to scrub.
- Never apologize for finding slop. Finding it is the job. Reporting "clean" when you didn't actually check is the failure.
