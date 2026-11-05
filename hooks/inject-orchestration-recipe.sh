#!/usr/bin/env bash
# Shared Claude Code / Codex UserPromptSubmit context hook; see README.md.
# Keep apostrophes out of recipes: Bash 3.2 misparses them inside $(heredoc).

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'orchestration hook: jq is required on PATH' >&2
  exit 2
fi

input="$(cat)" || exit 2
[ -z "$(printf '%s' "$input" | tr -d '[:space:]')" ] && exit 0

if ! prompt="$(printf '%s' "$input" | jq -ers '
  if length != 1 or (.[0] | type) != "object" then
    error("expected one JSON object")
  elif (.[0].prompt != null and (.[0].prompt | type) != "string") then
    error("prompt must be a string or null")
  else .[0].prompt // "" end
')"; then
  printf '%s\n' 'orchestration hook: invalid UserPromptSubmit input' >&2
  exit 2
fi

[ -z "$prompt" ] && exit 0

if printf '%s' "$prompt" | grep -qE '\?[[:space:]]*$'; then
  exit 0
fi

permission_mode="$(printf '%s' "$input" | jq -r '.permission_mode // ""')" || exit 2

# Quoted examples and code blocks must not become a local execution request.
intent="$(printf '%s' "$prompt" | jq -Rrs '
  gsub("(?s)```.*?```"; " ") |
  gsub("`[^`]*`"; " ") |
  gsub("\"(?:\\\\.|[^\"\\\\])*\""; " ") |
  gsub("(?s)(?<![[:alnum:]])\u0027.*?\u0027"; " ")
')" || exit 2
prompt_lc="$(printf '%s' "$intent" | LC_ALL=C tr '[:upper:]' '[:lower:]' | tr '\r\n\t' '   ' | tr -s ' ')"

TRIGGER_WORDS='orchestrate( a| an)?( uc| ultracode)? workflow|(uc|ultracode) workflow'
TRIGGER_RE="(^|[^[:alnum:]_])($TRIGGER_WORDS)([^[:alnum:]_]|$)"

if ! printf '%s' "$prompt_lc" | grep -qE "$TRIGGER_RE"; then
  exit 0
fi

ABOUT_RE='^[[:space:]]*(please[[:space:]]+)?(explain|describe|discuss|what|why|how|tell me about|can you explain)([[:space:]]|$)'
NEGATED_TRIGGER_RE="(^|[^[:alnum:]_])(do not|don.t|never|avoid|without|no need to|not to)[[:space:]]+($TRIGGER_WORDS|((start|create|run)( a| an)? (uc|ultracode) workflow))"
if printf '%s' "$prompt_lc" | grep -qE "$ABOUT_RE|$NEGATED_TRIGGER_RE"; then
  exit 0
fi

PLAN_RE='(^|[^[:alnum:]_])(plan|outline|design|scope|estimat|propos)|(^|[^[:alnum:]_])specs?([^[:alnum:]_]|$)'
EXPLICIT_RUN_RE='(^|[^[:alnum:]_])(plan|outline|design|scope|estimate|propose)[[:space:]]+(and|then)[[:space:]]+(run|execute|build|ship|implement)([^[:alnum:]_]|$)'
PLAN_LOCK_RE='(^|[^[:alnum:]_])(plan[ -]only|only[[:space:]]+plan|stop[[:space:]]+at[[:space:]]+(the[[:space:]]+)?plan|(do[[:space:]]+not|don.t|never)[[:space:]]+(run|execute|build|ship|implement)|without[[:space:]]+(run(ning)?|execut(e|ing|ion)|build(ing)?|ship(ping)?|implement(ing)?)|no[[:space:]]+execution)([^[:alnum:]_]|$)'

is_plan_only=false
if [ "$permission_mode" = plan ] \
   || printf '%s' "$prompt_lc" | grep -qE "$PLAN_LOCK_RE"; then
  is_plan_only=true
elif printf '%s' "$prompt_lc" | grep -qE "$PLAN_RE" \
   && ! printf '%s' "$prompt_lc" | grep -qE "$EXPLICIT_RUN_RE"; then
  is_plan_only=true
fi

if $is_plan_only; then
recipe="$(cat <<'RECIPE'
>>> ORCHESTRATION RECIPE, PLAN-ONLY VARIANT (auto-injected; this reads as a PLAN request, not a run) <<<

The user asked to PLAN / design / scope this, not to run it. Do NOT turn a working fleet loose.
Use the instructions and available agent tools for this runtime: CLAUDE.md in Claude Code,
AGENTS.md in Codex. Rigs belong in ~/.claude/rigs/ or ${CODEX_HOME:-~/.codex}/rigs/,
or an existing repo test folder. Never invent an unavailable model or scheduling API.

1. PRODUCE THE PLAN ONLY. Decompose into testable chunks; name the seats you WOULD spawn,
   the per-seat model tier, where adversarial review and real tests would sit.

2. READ-ONLY SCOUTS ONLY. You may spawn read-only scout agents to ground the plan in the
   real codebase. Spawn NOTHING that writes, edits, builds, or deploys.

3. PROJECT THE COST FOR APPROVAL. State the full cost of the run: total SEAT COUNT, per-seat
   MODEL TIER using models actually available in this tool/account, and the in-code
   FLEET_CAP the run would enforce. The cap never exceeds 7 concurrent, or a lower runtime cap.
   Claude examples: Fable for review, Opus for building, Sonnet for mechanical work.
   Codex: inherit the configured model unless the user or applicable instructions authorize
   a specific override. Never relabel a Codex model as a Claude model.
   Fix loops count as ONE combined seat, not one per fix.
   Also state a clock from measured numbers when available; otherwise label about 120 output
   tokens a second per agent as an unmeasured planning assumption, plus
   the rig run time. Give minutes per stage, the first clickable draft and the finish,
   against a 60-minute target. If it cannot hit 60, name the wall and its number.
   Plan around the KEEP THE RIG and CONTRACT FIRST rules: look in the tool-specific rigs folder before
   planning a rig agent, and write the shared contract first so chunks can run at once.

4. STOP AT THE PLAN. End by asking for approval before any execution. The plan is the
   deliverable; do not drift into building it.

>>> END PLAN-ONLY VARIANT <<<
RECIPE
)"
else
recipe="$(cat <<'RECIPE'
>>> ORCHESTRATION RECIPE (auto-injected; the user asked for a multi-agent workflow) <<<

The user asked for a multi-agent workflow. Within their stated task, build, test and review
the local work. This recipe never expands their authorization or overrides plan mode,
permissions, managed policy, spending controls or hook trust. Apply all of the following:

TOOL ADAPTER: In Claude Code, read ~/.claude/CLAUDE.md and use ~/.claude/rigs/.
In Codex, read the applicable AGENTS.md instructions and use ${CODEX_HOME:-~/.codex}/rigs/.
Use the available agent scheduler; pipeline() and parallel() below describe scheduling
patterns, not APIs that every tool provides. Never invent a missing tool or model.

COST GATE (announce this BEFORE you spawn anything):
 - State planned SEAT COUNT, per-seat MODEL TIER, and the in-code FLEET_CAP.
 - Every workflow script MUST enforce FLEET_CAP in code, a hard cap, not a prose promise,
   and FLEET_CAP never exceeds 7 concurrent agents, or a lower runtime/policy limit.
 - Fix/retry loops get ONE combined seat, never one seat per fix.
 - If the job wants more than ~10 agents total, pause and confirm scale before launching.
 - State a clock from measured numbers when available; otherwise label about 120 output
   tokens a second per agent as an unmeasured planning assumption, plus the
   rig run time. Give minutes per stage, the first clickable draft and the finish, against
   a 60-minute target. If it cannot hit 60, name the wall and its number before launch.
 - At twice the time planned for a stage, tell the user and revise or split the work within
   the approved budget and concurrency limit; never launch extra seats to evade a cap.
   Every status note gives time left. Run page-wide checks before fanning out.
 - Before calling a stage done, compare agents planned with agents run, because a BLOCKED
   agent skips whatever sits behind it.

1. TIER ROUTING. Use available models and the applicable user instructions. Reserve capable
   reasoning models for correctness, adversarial review, security, money paths and
   anti-fabrication; use cheaper capable models for mechanical work. Claude examples:
   Fable for review, Opus for building/writing, Sonnet for mechanical execution.
   In Codex, inherit the configured model unless a specific override is authorized.
   State a one-line reason for any routing deviation, including unavailable model tiers.

2. CHUNK BY TESTABLE CHUNK. Decompose into independently testable pieces. Pipeline them
   (run stages independently, not as one big synchronized barrier, unless a stage truly
   needs all prior results at once).
   CONTRACT FIRST: write the shared contract first, in one agent, in about 5 minutes. Then each
   chunk runs its spec, build, test and review as a pipeline within FLEET_CAP, with fixes
   going to the one combined fix seat. Avoid a full-fleet barrier unless dependencies need it. Anything that
   needs no finished build, like a talk track or a critic on the contract, starts at the
   same moment.

3. ADVERSARIAL REVIEW + REAL TESTS ON EVERY CHUNK. As each chunk finishes it gets an
   independent skeptic/adversarial review AND a real test, interleaved per chunk, NOT one
   pass bolted on at the end.

4. TESTS ARE REAL, NEVER "MEANT TO PASS." Tests must exercise real behavior, be capable of
   FAILING, and assert against the actual artifact (the DB row, the file, the live state).
   No trivially-green checks. Never mock away the thing under test. Confirm the real change
   yourself; do not trust an exit code or an agent claiming success.
   TEST LESS OFTEN, NEVER LESS: while building, run only what changed, in one browser. A chunk
   gets one full relevant pass when done, and the final artifact gets one more. For browser
   work, cover the supported browsers and sizes within resource limits. For a CLI or hook,
   test real stdin/stdout/stderr and the supported shells rather than inventing a browser task.
   KEEP THE RIG: retain a reusable test rig, and a page shell when applicable, in the
   tool-specific rigs folder or the existing repo test folder. Look there before planning a
   rig agent. Reuse a passing rig self-test only when the rig, dependencies and environment
   match recorded evidence; actual artifact tests still run. If any changed, rerun the rig
   self-test while independent work proceeds, and hold completion for it.

5. EXPERT-GRADE AGENT PROMPTS. Every sub-agent prompt carries all three, no exceptions:
   a clear expert ROLE ("You are a senior X responsible for Y"), an explicit DEFINITION OF
   DONE including the tests or evidence that prove it, and RED-FLAG PROTOCOLS (when
   something looks wrong: stop and report back, never improvise around a blocker, never
   fabricate results or claim untested work passes).

6. SCALE TO THE ASK. "Quick check" = a few agents. "Audit / thorough" = bigger finder pool,
   multi-vote adversarial verify, synthesis. NO SILENT CAPS: if you sample, cap, or skip
   retries, say so out loud.

7. LOOP UNTIL GENUINELY COMPLETE. Keep orchestrating until every chunk is built, reviewed,
   and tested (loop-until-dry on open-ended discovery work). If review or a test fails for
   any chunk, fix and re-verify before moving on. Never hand back partial work as done.

8. AUTONOMY GATE. For an affirmative execution request, proceed with local work already
   authorized by the user: build/test/review/iterate within that task. STILL hard-stop for
   explicit approval before anything that LEAVES THE MACHINE or is hard to undo: deploy,
   send an email, post to Slack or social, write to an external system, force-push,
   external API writes, including ordinary commits/pushes/PR creation when not authorized.
   Cloud model requests and public read-only lookups are network activity; never describe
   them as offline. Do not upload private artifacts or publish changes without approval.
   This is an instruction to the model; enforce tool/network restrictions in permissions.
   Announce the plan up front so it can be aborted, then proceed.

9. REPORT BACK STRAIGHT. End with: what was done, what is verified (with evidence), what
   failed (with the actual output), what remains. No confident guessing.

>>> END RECIPE <<<
RECIPE
)"
fi

if ! jq -n --arg ctx "$recipe" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $ctx
  }
}'; then
  exit 2
fi

exit 0
