# Slop-scrub enhancements: contractions, staccato, and author voice

## Scope

Improve the prose-writing checklist only. This proposal does not change code-comment hygiene or workflow orchestration.

## Proposal 1: natural contractions and the staccato check

### Contractions

Replace the blanket instruction to contract every possible form with a voice-sensitive check. Agents should notice when expanded forms make conversational writing sound stiff, but should keep expanded forms when they add emphasis, fit a formal passage, or match the author's usage. Preserve the meaning of each phrase, including `let us` in phrases such as "let us know."

### Staccato check

Add checklist item 13. It identifies adjacent runs of two or more short (about 12 words or fewer), declarative, standalone claims that are parallel in shape and have no connective between them. Such a run reads like a list of verdicts.

- Rewrite a run of three or more qualifying sentences.
- Flag two qualifying sentences for review. Rewrite when both are also uncontracted.
- Fix the run by stating the relationship with a connective, varying sentence length deliberately, or adding a concrete supporting example.
- Keep one short sentence after a longer sentence when the contrast is useful.
- Exempt headlines, bullets, calls to action, captions, table cells, and named-person quotations.

## Proposal 2: project-root VOICE.md

### Convention

Define an optional `VOICE.md` at the consuming project's root. It contains two or three short pieces the author wrote and approved, verbatim, plus one line describing the reader. The agent reads the whole file on every scrub run and does not rely on remembered samples.

### Uses during a scrub

1. Calibrate sentence length, directness, vocabulary, and the author's use of `I` versus `we`.
2. Apply the author test: would this writer say this sentence aloud to this reader?
3. Re-read the cleaned text beside the samples. If a reader could recognize the samples as the author's work but not the scrubbed text, revise the edit to preserve the voice.

### Guards

- Samples calibrate voice; they do not permit banned items.
- Never scrub or edit the samples.
- Put a `VOICE` line at the top of the scrub report, stating whether the file was found and used.
- If there is no file, say so in the report and offer to build one from two pieces the author selects. Never invent a voice or write samples on the author's behalf.

### Repository updates

- Add `examples/VOICE.md.template` with placeholders, not personal sample writing.
- Add one sentence to the README explaining the convention and linking to the template.
- Update the checklist's report format and voice-preservation rules.

## Rationale

Real writing samples give the agent evidence it can imitate. Adjectives such as "warm" or "direct" do not show the author's actual sentence rhythm and word choices. The author test is the voice counterpart to checklist item 9's swap test: item 9 asks whether a company is replaceable; this test asks whether the writer is.

## Acceptance checks

- Contractions remain a judgment based on grammar, emphasis, audience, and author voice; there is no blanket requirement to contract every possible form.
- The staccato check states its sentence criteria, thresholds, repairs, and exemptions.
- The agent reads a present root `VOICE.md` in full every run and reports its status.
- Missing samples trigger an offer to use two author-selected pieces, not invented examples.
- The sample template contains no real person's private or unpublished writing.
- The scope remains limited to slop-scrub prose guidance and related documentation.
