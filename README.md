# guardrail-skills

Three small, independent guardrails for AI coding agents. Each one works two ways: as a **skill** (the agent decides when to run it) or as a **hook** (your tooling forces it to run every time, whether the agent remembers or not). Neither mode requires Claude Code specifically; see the install notes under each one.

## slop-scrub

**What it is:** a 12-point checklist that catches AI writing tells: em dashes, banned words ("delve," "robust," "unlock"), fake profundity, fabricated stats, engagement-bait endings.

**Why it was built:** AI-generated copy has predictable, catchable patterns that make it read as obviously AI-written. Most of them are individually easy to miss but obvious in aggregate, so a one-off glance at a draft doesn't reliably catch them. A checklist run every time does.

**Why it's useful:** anything you publish under your own name (emails, social posts, docs, blog content) reads better and less generic once these tells are gone.

**What it looks like.** Before:

> In today's fast-paced world, developers navigate an increasingly complex landscape of tooling. Our robust CLI empowers engineers to seamlessly unlock their workflow potential — it's not just a task runner, it's a paradigm shift. Studies show 87% of developers lose hours to context switching. Ready to transform how your team ships? Drop a comment below.

After:

> Most task runners make you learn a new config language. This one reads the scripts already in your `package.json` and runs them in parallel, without the output interleaving into mush.

Caught in that one paragraph: eight banned words and phrases (`in today's fast-paced world`, `navigate`, `landscape`, `robust`, `empowers`, `seamlessly`, `unlock`, `paradigm`), an "it's not X, it's Y" construction, an em dash, a statistic with no source behind it, and an engagement-bait closer.

**The banned-word list is a starting point, not a ruling.** You'll disagree with parts of it, and you should. `leverage` and `robust` have honest uses. Open `skills/slop-scrub/SKILL.md`, edit the list in item 1, and make it yours. Forking it into something opinionated about *your* writing is the intended use, not a misuse.

**As a skill:** copy `skills/slop-scrub/SKILL.md` into your tool's skills/instructions folder (for Claude Code: `~/.claude/skills/slop-scrub/`). In Claude Code it's then available as `/slop-scrub`. On any other AI tool, paste everything below the `---` frontmatter into your system prompt or custom instructions; it's self-contained.

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

A Claude Code hook. It's enforcement, not something an agent opts into, so there's no "skill" mode for it: install it and it just runs.

**What it is:** a hook that auto-injects your own standing multi-agent-workflow instructions the moment your prompt matches a trigger phrase.

**Why it was built:** re-typing the same instructions ("chunk it, adversarial review every chunk, real tests, pick model tiers by complexity") every time you kick off a multi-agent run is tedious, and putting them in a file the model reads every session weighs down every unrelated conversation too. A hook injects them only on the prompts that actually ask for a workflow.

**Why it's useful:** consistent multi-agent runs without re-explaining your standards each time, and without bloating every other session.

**Install:** copy `hooks/inject-orchestration-recipe.sh` to `~/.claude/hooks/`, wire it into `~/.claude/settings.json` under `UserPromptSubmit`, then edit `TRIGGER_RE` near the top of the script to match your own trigger phrase, and edit the recipe text further down to match how *you* actually want a fleet run. The shipped version is one opinionated example, not a standard to follow verbatim.

---

## License

MIT. See [LICENSE](LICENSE).
