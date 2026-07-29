#!/usr/bin/env bash
# ~/.claude/hooks/inject-orchestration-recipe.sh
#
# UserPromptSubmit hook — when you ask for a multi-agent workflow, this
# quietly slips your own standing orchestration recipe into the model's view
# for that one prompt. The point: you should never have to re-type "do it
# thoroughly, chunk it, adversarial review, real tests, pick model tiers by
# complexity, loop until done" ever again. You type your trigger phrase; the
# recipe shows up fresh, every time, in every session.
#
# WHY A HOOK INSTEAD OF A STANDING PROJECT INSTRUCTION FILE (e.g. CLAUDE.md):
# these rules only matter when you're actually orchestrating. Baking them into
# a file the model reads every session would weigh down every unrelated
# conversation. A hook injects them ONLY on the prompts that ask for a
# workflow.
#
# WHAT FIRES IT: phrases matching TRIGGER_RE below. Shipped default matches
# "orchestrate a workflow" / "orchestrate an ultracode workflow" / "uc
# workflow" / "ultracode workflow" — "ultracode" here is just this repo's
# example personal shorthand for the trigger. Replace it with your own coined
# phrase, or delete it and keep the plain "orchestrate a workflow" form.
#
# WHAT IT DELIBERATELY SKIPS: prompts that end in "?" — those are usually you
# asking ABOUT workflows, not asking for one. Cheap guard against firing on a
# question. If a real command ever ends in "?" and gets skipped, no harm
# done — you just won't see the recipe that once, and can rephrase.
#
# PLAN vs RUN: once a trigger matches, we look again at the SAME prompt. If it
# reads as a PLAN-shaped ask (plan/outline/design/spec/estimate/propose) with
# NO run verb (run/execute/build/ship/go), we inject a lighter PLAN-ONLY
# variant — produce the plan, spawn only read-only scouts, price the full run
# for approval — instead of turning a fleet loose. "plan and execute" carries
# a run verb, so it stays run-shaped and gets the full recipe.
#
# To change the trigger words: edit TRIGGER_RE below. To turn this off:
# remove the UserPromptSubmit block from your settings.json.

set -uo pipefail

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // ""')"

[ -z "$prompt" ] && exit 0

# Skip obvious questions: if the prompt's last non-whitespace character is
# "?", the user is almost certainly asking ABOUT orchestration, not commanding
# it. Stay silent.
if printf '%s' "$prompt" | grep -qE '\?[[:space:]]*$'; then
  exit 0
fi

prompt_lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"

# EDIT ME: this is the one line most people customize. The shipped default
# matches "orchestrate a workflow" plus an example personal shorthand ("uc" /
# "ultracode"). Swap in your own coined phrase, or trim it down to just the
# plain form if you don't want a shorthand at all.
TRIGGER_RE='orchestrate( a| an)?( uc| ultracode)? workflow|(uc|ultracode) workflow'

if ! printf '%s' "$prompt_lc" | grep -qE "$TRIGGER_RE"; then
  exit 0
fi

# --- Triggered. Decide: is this a PLAN-shaped ask or a RUN-shaped one? ---
# Plan verbs (plan/outline/design/spec/estimate/propose) with NO run verb
# (run/execute/build/ship/go) => plan-only. A run verb anywhere wins, so "plan
# and execute" is run-shaped. Stems + word boundaries keep run verbs from
# over-matching ("go" is bounded so "google" doesn't count as a run; "spec" is
# bounded so "inspect" doesn't count as a plan) — over-matching run would
# wrongly turn a fleet loose on a planning request, the exact thing this guard
# exists to prevent.
PLAN_RE='\b(plan|outline|design|estimat|propos)|\bspecs?\b'
RUN_RE='\b(run|execut|build|ship)|\bgo\b'

is_plan_only=false
if printf '%s' "$prompt_lc" | grep -qE "$PLAN_RE" \
   && ! printf '%s' "$prompt_lc" | grep -qE "$RUN_RE"; then
  is_plan_only=true
fi

# --- Triggered. Inject the orchestration recipe. ---
# This text is written AS A DIRECTIVE TO THE MODEL (future-you, reading this
# in context). It's your standing instruction, made explicit every time
# instead of relying on you retyping it. Plan-shaped asks get the lighter
# PLAN-ONLY variant; run-shaped asks get the full recipe.
if $is_plan_only; then
recipe="$(cat <<'RECIPE'
>>> ORCHESTRATION RECIPE — PLAN-ONLY VARIANT (auto-injected — this reads as a PLAN request, not a run) <<<

The user asked to PLAN / design / scope this, not to run it. Do NOT turn a working fleet loose.

1. PRODUCE THE PLAN ONLY. Decompose into testable chunks; name the seats you WOULD spawn,
   the per-seat model tier, where adversarial review + real tests would sit.

2. READ-ONLY SCOUTS ONLY. You may spawn read-only scout agents to ground the plan in the
   real codebase. Spawn NOTHING that writes, edits, builds, or deploys.

3. PROJECT THE COST FOR APPROVAL. State the full cost of the run: total SEAT COUNT, per-seat
   MODEL TIER (grunt tier for mechanical work, judgment tier for design/review), and the
   in-code FLEET_CAP the run would enforce. Fix loops count as ONE combined seat, not one
   per fix.

4. STOP AT THE PLAN. End by asking for approval before any execution. The plan is the
   deliverable — do not drift into building it.

>>> END PLAN-ONLY VARIANT <<<
RECIPE
)"
else
recipe="$(cat <<'RECIPE'
>>> ORCHESTRATION RECIPE (auto-injected — the user asked for a multi-agent workflow) <<<

The user wants a real multi-agent workflow here, not a solo pass. Treat the trigger phrase
as their approval to run the full local job autonomously. Build and run the workflow. Apply
ALL of the following — this is their standing, repeated instruction:

COST GATE (announce this BEFORE you spawn anything):
 - State planned SEAT COUNT, per-seat MODEL TIER, and the in-code FLEET_CAP.
 - Every workflow script MUST enforce FLEET_CAP in code — a hard cap, not a prose promise.
 - Fix/retry loops get ONE combined seat, never one seat per fix.

1. TIER PINNING. Pin grunt/mechanical seats to the cheapest capable model tier in your fleet.
   Reserve your highest-judgment tier for judgment only — planning, design, adversarial
   review, synthesis, security-sensitive builds. Never run the whole fleet on one tier;
   announce any deviation out loud.

2. CHUNK BY TESTABLE CHUNK. Decompose into independently testable pieces. Pipeline them
   (run stages independently, not as one big synchronized barrier, unless a stage truly
   needs all prior results at once).

3. ADVERSARIAL REVIEW + REAL TESTS ON EVERY CHUNK. As each chunk finishes it gets an
   independent skeptic/adversarial review AND a real test — interleaved per chunk, NOT one
   pass bolted on at the end.

4. TESTS ARE REAL, NEVER "MEANT TO PASS." Tests must exercise real behavior, be capable of
   FAILING, and assert against the actual artifact (the DB row, the file, the live state).
   No trivially-green checks. Never mock away the thing under test. Never assert the obvious.
   Confirm the real change yourself — do not trust an exit code or an agent claiming success.

5. EXPERT-GRADE AGENT PROMPTS. Every sub-agent prompt is expert-grade: role, context, exact
   task, hard constraints, explicit success criteria, required output format/schema. No lazy
   one-liners.

6. SCALE TO THE ASK. "Quick check" = a few agents. "Audit / thorough" = big finder pool +
   multi-vote adversarial verify + synthesis. NO SILENT CAPS — if you sample, cap, or skip
   retries, say so out loud.

7. LOOP UNTIL GENUINELY COMPLETE. Keep orchestrating until every chunk is built, reviewed,
   and tested (loop-until-dry on open-ended discovery work). If review or a test fails for
   any chunk, fix and re-verify before moving on. Never hand back partial work as done.

8. AUTONOMY GATE. The trigger phrase IS approval for the whole local job — run
   build/test/review/iterate to completion without stopping to ask. STILL hard-stop for
   explicit approval before anything that LEAVES THE MACHINE or is hard to undo: deploy,
   send an email, write to an external system, force-push, external API writes. Announce
   the plan up front so it can be aborted, then proceed.

9. REPORT BACK STRAIGHT. End with: what was done, what is verified (with evidence), what
   failed (with the actual output), what remains. No confident guessing.

>>> END RECIPE <<<
RECIPE
)"
fi

jq -n --arg ctx "$recipe" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'

exit 0
