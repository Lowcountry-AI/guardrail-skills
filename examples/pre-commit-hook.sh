#!/usr/bin/env bash
# Example git pre-commit hook: forces comment-scrub to run on every commit's
# staged diff, instead of relying on an agent remembering to invoke it. This
# is the "hook" (enforced) mode described in the main README, as opposed to
# the "skill" (agent-invoked) mode. Pair this with the GitHub Actions example
# for slop-scrub on copy/content changes — see examples/github-actions.yml.
#
# Install: copy this file to .git/hooks/pre-commit in your repo and
# `chmod +x` it. Or, if you use a hook manager (Husky, pre-commit, lefthook),
# wire it in as a normal shell step — the logic below doesn't depend on git
# hooks specifically.
#
# Swap `claude -p` for whatever CLI-capable AI tool you use if you're not on
# Claude Code — any tool that can take a prompt on stdin/argv and return text
# works the same way here.

set -euo pipefail

SKILLS_DIR="__PATH_TO_THIS_REPO__/skills"   # EDIT ME: point at wherever you cloned this repo

diff="$(git diff --cached)"
if [[ -z "$diff" ]]; then
  exit 0
fi

echo "Running comment-scrub on staged diff..."
comment_report="$(claude -p "$(cat "$SKILLS_DIR/comment-scrub/SKILL.md")

Scrub this diff. If everything is clean, respond with exactly the line CLEAN and nothing else. If anything needs fixing, respond with exactly the line NEEDS_FIXES and then the full report.

DIFF:
$diff")"

if [[ "$comment_report" != CLEAN* ]]; then
  echo "$comment_report"
  echo
  echo "comment-scrub found issues. Fix them, then re-stage and commit again."
  echo "(To bypass once: git commit --no-verify)"
  exit 1
fi

echo "comment-scrub: clean."
