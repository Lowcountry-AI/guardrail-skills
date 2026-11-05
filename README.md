# guardrail-skills

Three small, independent guardrails for AI coding agents. Each one works two ways: as a **skill** (the agent decides when to run it) or as a **hook** (your tooling forces it to run every time, whether the agent remembers or not). Neither mode requires Claude Code specifically; see the install notes under each one.

## slop-scrub

**What it is:** a 13-point checklist that catches AI writing tells: em dashes, banned words ("delve," "robust," "unlock"), fake profundity, fabricated stats, engagement-bait endings, and staccato runs of verdict-like sentences.

**Why it was built:** AI-generated copy has predictable, catchable patterns that make it read as obviously AI-written. Most of them are individually easy to miss but obvious in aggregate, so a one-off glance at a draft doesn't reliably catch them. A checklist run every time does.

**Why it's useful:** anything you publish under your own name (emails, social posts, docs, blog content) reads better and less generic once these tells are gone.

**What it looks like.** Before:

> In today's fast-paced world, developers navigate an increasingly complex landscape of tooling. Our robust CLI empowers engineers to seamlessly unlock their workflow potential — it's not just a task runner, it's a paradigm shift. Studies show 87% of developers lose hours to context switching. Ready to transform how your team ships? Drop a comment below.

After:

> Most task runners make you learn a new config language. This one reads the scripts already in your `package.json` and runs them in parallel, without the output interleaving into mush.

Caught in that one paragraph: eight banned words and phrases (`in today's fast-paced world`, `navigate`, `landscape`, `robust`, `empowers`, `seamlessly`, `unlock`, `paradigm`), an "it's not X, it's Y" construction, an em dash, a statistic with no source behind it, and an engagement-bait closer.

**The banned-word list is a starting point, not a ruling.** You'll disagree with parts of it, and you should. `leverage` and `robust` have honest uses. Open `skills/slop-scrub/SKILL.md`, edit the list in item 1, and make it yours. Forking it into something opinionated about *your* writing is the intended use, not a misuse.

**As a skill:** copy `skills/slop-scrub/SKILL.md` into your tool's skills/instructions folder (for Claude Code: `~/.claude/skills/slop-scrub/`). In Claude Code it's then available as `/slop-scrub`. On any other AI tool, paste everything below the `---` frontmatter into your system prompt or custom instructions; it's self-contained.

To preserve a project's writing voice, put two or three short, author-approved samples and one reader description in a root `VOICE.md`; start from [`examples/VOICE.md.template`](examples/VOICE.md.template).

**As a hook:** see [`examples/pre-commit-hook.sh`](examples/pre-commit-hook.sh) or [`examples/github-actions.yml`](examples/github-actions.yml) for how to force it to run on every commit or PR instead of waiting for the agent to remember.

---

## comment-scrub

**What it is:** a checklist that catches code comments that restate the code, apologize for bad code, or bury a commit-message narrative in the source. Ships with `COMMENTS.md`, the underlying comment-hygiene standard it enforces.

**Why it was built:** AI agents tend to over-comment: narrating obvious lines, writing multi-paragraph "why this exists" essays inline, leaving commented-out code behind. The fix isn't "write fewer comments" as a vague instruction, it's a specific, repeatable check.

**Why it's useful:** code that reads clean, where every comment that survives is actually earning its place instead of restating what the code already says.

**As a skill:** copy `skills/comment-scrub/` (both files) into your tool's skills folder. In Claude Code it's then available as `/comment-scrub`. On any other AI tool, paste the `SKILL.md` body into your instructions; pair it with `COMMENTS.md` if your tool supports a second reference file.

**As a hook:** same two examples as slop-scrub, this is the one you actually want on every commit. See [`examples/pre-commit-hook.sh`](examples/pre-commit-hook.sh).

---

## inject-orchestration-recipe.sh

A `UserPromptSubmit` hook for **Claude Code and Codex**. Both runtimes accept a JSON object with a `prompt` string on stdin and the `hookSpecificOutput.additionalContext` response below. The same script works in either tool; configuration and hook-trust steps differ.

When you ask to "orchestrate a workflow," the hook supplies a recipe for a cost and clock estimate, a shared contract, independent review and real tests for each chunk. It calls for a 60-minute target, retained test rigs, and a comparison of agents planned with agents actually run before a stage is complete.

The recipe is model context. Agent limits and approval boundaries still depend on the agent following it and the runtime enforcing its permissions. This script neither launches agents nor intercepts pushes, deployments, or external writes. Keep your permission controls and spend-cap hooks enabled. Cloud model requests also use the network; a local workflow is not an offline workflow.

**Requirements:** Bash 3.2 or newer, `jq`, and standard `cat`, `grep`, and `tr` commands. Review the script before enabling it. Stop if managed policy disallows user hooks; do not change policy or bypass hook trust.

**Before installing:** back up each existing destination to the same name plus `.bak-orchestration`; never overwrite an existing backup. Resolve symlinks and preserve both the link and its target. Keep backups and machine-specific settings out of source control. These examples show entries to merge into your configuration, not replacement files. If installation or validation fails, stop, restore only this install's changes from the backups, and report the actual error output.

**Install (Claude Code):** copy the script to `~/.claude/hooks/inject-orchestration-recipe.sh`, make it executable, and merge this entry into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/inject-orchestration-recipe.sh\"" }] }
    ]
  }
}
```

Preserve all other settings and hooks. If this command is already registered, update its script without adding another registration. Validate the result with `jq empty ~/.claude/settings.json`. Check `/hooks` in Claude Code, then start a fresh session for the smoke test.

**Install (Codex):** copy the same script to `${CODEX_HOME:-$HOME/.codex}/hooks/inject-orchestration-recipe.sh`, make it executable, and merge this entry into `${CODEX_HOME:-$HOME/.codex}/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"${CODEX_HOME:-$HOME/.codex}/hooks/inject-orchestration-recipe.sh\"",
          "additionalContextLimit": 5000
        }]
      }
    ]
  }
}
```

Preserve existing hooks, including spend controls. Codex also supports inline `[hooks]` configuration; use one representation per configuration layer to avoid duplicates. Validate `hooks.json` with `jq empty`, then open `/hooks` in the CLI or Settings > Hooks in the app to review and trust the new hook. Registration alone does not activate an untrusted hook. Do not edit stored trust hashes or use trust-bypass flags as an installation step. The bounded `additionalContextLimit` keeps this recipe together instead of relying on Codex's default spill threshold.

**Standing rules:** [examples/orchestration-rules.md](examples/orchestration-rules.md) contains the companion section. In Claude Code, append it to `~/.claude/CLAUDE.md`; in Codex, use `${CODEX_HOME:-$HOME/.codex}/AGENTS.md`. If the section exists, compare and merge it rather than appending a duplicate. Claude examples name Fable, Opus and Sonnet; Codex uses its available models and inherits the configured model unless an override is authorized. Stop and report missing required models instead of inventing names or changing account settings.

The recipe reuses an existing repository test rig or a tool-specific rigs folder. Create `~/.claude/rigs/` or `${CODEX_HOME:-$HOME/.codex}/rigs/` only if needed. The writing and comment checks use this repository's independent skills; installing the hook does not download or install those skills.

**Plan versus execution:**

| Prompt | Hook output |
| --- | --- |
| `orchestrate a workflow to update one file` | Full recipe |
| `orchestrate a workflow and outline the plan for a one-file change.` | Plan-only recipe |
| `orchestrate a workflow and outline a plan to build a tool` | Plan-only recipe |
| `plan and execute an uc workflow` | Full recipe |
| `orchestrate a workflow, do not execute` | Plan-only recipe |
| `what time is it` | No output |
| `can you orchestrate a workflow?` | No output |
| `Explain the phrase "orchestrate a workflow".` | No output |

The aliases `uc workflow` and `ultracode workflow` are personal shorthand you can change. Matches are case-insensitive and accept whitespace between words. Questions ending in `?`, quoted examples, code spans/blocks and negated triggers are skipped. Planning language defaults to the plan-only recipe, even when it describes building or shipping. An explicit `plan and execute` or `plan then run` selects execution; `plan only`, negated execution and the runtime's `permission_mode: "plan"` keep the plan-only variant. These are conservative text heuristics, not a natural-language permission parser. Existing user instructions and runtime policy remain authoritative.

Empty or missing prompts produce no output. Malformed JSON, non-object events, multiple JSON documents, wrong prompt types and missing `jq` produce an error on stderr and exit 2. In either tool, exit 2 from `UserPromptSubmit` blocks the prompt. A hook that never starts or is skipped cannot inject instructions; do not assume it provides an enforcement boundary.

**Test locally:**

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The suite invokes the actual hook under `/bin/bash`, checks stdout/stderr and the JSON schema, and runs a mutated-script negative control to prove a missing recipe requirement fails an assertion. It uses no model account, network or external writes. To test an installed copy directly:

```sh
H="$HOME/.claude/hooks/inject-orchestration-recipe.sh" # or the Codex hook path
jq -n --arg prompt 'orchestrate a workflow and outline the plan for a one-file change.' \
  '{prompt: $prompt}' | /bin/bash "$H"
```

Then start a fresh session in each tool and enter that same plan-only prompt. Confirm the hook is loaded and trusted and the model stops at the plan. Direct script tests establish the hook's response; a live session establishes runtime loading and model behavior. Report an authentication or trust blocker separately rather than claiming a live test passed.

Keep apostrophes out of the recipe heredocs while they remain inside command substitutions: macOS Bash 3.2 can fail to parse that construction. Rerun the suite after any edit.

Hook contracts and Codex trust/context settings: [Claude Code hooks](https://code.claude.com/docs/en/hooks), [Codex hooks](https://learn.chatgpt.com/docs/hooks).

---

## Contributing

Issues and pull requests are open. Bug reports, focused improvements, and additions to the banned-word list are welcome. These checklists work best when you adapt them to your writing and code, so forking them for your own rules is welcome too.

---

## License

MIT. See [LICENSE](LICENSE).
