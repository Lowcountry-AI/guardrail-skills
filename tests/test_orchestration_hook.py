import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
HOOK = Path(
    os.environ.get("ORCHESTRATION_HOOK_PATH")
    or REPO / "hooks" / "inject-orchestration-recipe.sh"
).expanduser().resolve()
EVIDENCE_ENV = "ORCHESTRATION_HOOK_TEST_EVIDENCE"
RUN_MARKERS = (
    "CONTRACT FIRST",
    "TEST LESS OFTEN",
    "KEEP THE RIG",
    "60-minute target",
    "compare agents planned",
)


class OrchestrationHookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.records = []
        cls.negative_controls = []
        cls.hook_sha256 = hashlib.sha256(HOOK.read_bytes()).hexdigest()
        cls.bash_version = subprocess.run(
            ["/bin/bash", "--version"],
            text=True,
            capture_output=True,
            check=True,
        ).stdout.splitlines()[0]
        cls.jq = shutil.which("jq")
        if cls.jq is None:
            raise RuntimeError("The behavior suite requires real jq on PATH")

    @classmethod
    def tearDownClass(cls):
        evidence_path = os.environ.get(EVIDENCE_ENV)
        if evidence_path:
            Path(evidence_path).write_text(
                json.dumps(
                    {
                        "hook": str(HOOK),
                        "hook_sha256": cls.hook_sha256,
                        "bash_version": cls.bash_version,
                        "jq": cls.jq,
                        "subprocesses": cls.records,
                        "negative_controls": cls.negative_controls,
                    },
                    indent=2,
                    ensure_ascii=False,
                )
                + "\n",
                encoding="utf-8",
            )

    def run_hook(self, payload=None, *, raw=None, path=HOOK, env=None):
        if raw is None:
            raw = json.dumps(payload, ensure_ascii=False)
        process_env = os.environ.copy()
        process_env.pop("BASH_ENV", None)
        process_env.pop("ENV", None)
        process_env["LC_ALL"] = "C"
        if env:
            process_env.update(env)
        result = subprocess.run(
            ["/bin/bash", str(path)],
            input=raw,
            text=True,
            encoding="utf-8",
            capture_output=True,
            timeout=10,
            cwd=REPO,
            env=process_env,
        )
        self.records.append(
            {
                "test": self.id(),
                "hook": str(path),
                "hook_sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest(),
                "stdin": raw,
                "exit_code": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            }
        )
        return result

    def assert_silent(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")

    def assert_invalid(self, result, diagnostic):
        self.assertEqual(result.returncode, 2, repr(result))
        self.assertEqual(result.stdout, "")
        self.assertTrue(result.stderr.strip(), "Invalid input needs a diagnostic")
        self.assertRegex(result.stderr.lower(), diagnostic)

    def context(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")

        def unique_pairs(pairs):
            output = {}
            for key, value in pairs:
                self.assertNotIn(key, output, "Duplicate JSON output key")
                output[key] = value
            return output

        try:
            output = json.loads(result.stdout, object_pairs_hook=unique_pairs)
        except json.JSONDecodeError as error:
            self.fail("Hook stdout must contain only one JSON object: " + str(error))
        self.assertIsInstance(output, dict)
        self.assertEqual(set(output), {"hookSpecificOutput"})
        event = output["hookSpecificOutput"]
        self.assertIsInstance(event, dict)
        self.assertEqual(set(event), {"hookEventName", "additionalContext"})
        self.assertEqual(event["hookEventName"], "UserPromptSubmit")
        self.assertIsInstance(event["additionalContext"], str)
        self.assertTrue(event["additionalContext"].strip())
        return event["additionalContext"]

    def assert_run(self, result):
        context = self.context(result)
        normalized = re.sub(r"\s+", " ", context)
        self.assertNotIn("PLAN-ONLY VARIANT", context)
        self.assertIn(">>> END RECIPE <<<", context)
        for marker in RUN_MARKERS:
            self.assertTrue(marker in normalized, "Missing run marker: " + marker)
        return context

    def assert_plan_only(self, result):
        context = self.context(result)
        normalized = re.sub(r"\s+", " ", context).upper()
        for marker in (
            "PLAN-ONLY VARIANT",
            "PRODUCE THE PLAN ONLY",
            "READ-ONLY SCOUTS ONLY",
            "STOP AT THE PLAN",
            "CONTRACT FIRST",
            "KEEP THE RIG",
            "60-MINUTE TARGET",
        ):
            self.assertTrue(marker in normalized, "Missing plan marker: " + marker)
        self.assertNotIn(">>> END RECIPE <<<", context)
        return context

    def test_run_has_exact_schema_and_required_recipe(self):
        self.assert_run(self.run_hook({"prompt": "orchestrate a workflow"}))

    def test_claude_and_codex_payloads_allow_extra_model_fields(self):
        payloads = (
            {
                "session_id": "claude-fixture",
                "transcript_path": "/unused/claude-session.jsonl",
                "cwd": str(REPO),
                "permission_mode": "default",
                "hook_event_name": "UserPromptSubmit",
                "model": "claude-sonnet-fixture",
                "prompt": "orchestrate a workflow",
            },
            {
                "session_id": "codex-fixture",
                "transcript_path": "/unused/codex-session.jsonl",
                "cwd": str(REPO),
                "permission_mode": "default",
                "hook_event_name": "UserPromptSubmit",
                "provider": "openai",
                "model": "configured-codex-fixture",
                "extra": {"nested": [1, True, None]},
                "prompt": "orchestrate a workflow",
            },
        )
        contexts = []
        for payload in payloads:
            with self.subTest(session_id=payload["session_id"]):
                contexts.append(self.assert_run(self.run_hook(payload)))
        self.assertEqual(contexts[0], contexts[1])

    def test_aliases_case_and_whitespace(self):
        prompts = (
            "orchestrate workflow",
            "orchestrate a workflow",
            "orchestrate an ultracode workflow",
            "orchestrate a uc workflow",
            "uc workflow",
            "ultracode workflow",
            "ORCHESTRATE A WORKFLOW",
            "Please OrChEsTrAtE An UlTrAcOdE WoRkFlOw now.",
            "  orchestrate\ta\tworkflow  ",
            "orchestrate  an   ultracode  workflow",
            "uc\nworkflow",
            "\n orchestrate\r\n a\r\n workflow\t",
        )
        for prompt in prompts:
            with self.subTest(prompt=prompt):
                self.assert_run(self.run_hook({"prompt": prompt}))

    def test_unrelated_prompts_are_silent(self):
        for prompt in (
            "Please explain the code.",
            "Build the dashboard.",
            "I need an orchestra workflow.",
            "The document contains workflow guidance.",
            "duc workflow",
            "uc workflows",
            "ultracode workflowing",
        ):
            with self.subTest(prompt=prompt):
                self.assert_silent(self.run_hook({"prompt": prompt}))

    def test_questions_are_silent(self):
        for prompt in (
            "What is an ultracode workflow?",
            "Can you orchestrate a workflow?",
            "orchestrate a workflow?   \n\t",
            "Plan an uc workflow?\r\n",
            "Explain how to orchestrate a workflow.",
            "Why orchestrate a workflow.",
            "Please describe an ultracode workflow.",
        ):
            with self.subTest(prompt=prompt):
                self.assert_silent(self.run_hook({"prompt": prompt}))

    def test_quoted_and_negated_triggers_are_silent(self):
        for prompt in (
            'Use "uc workflow" as a label.',
            "The docs say 'orchestrate a workflow'.",
            "Document `ultracode workflow` in the README.",
            "Document this example:\n```\norchestrate a workflow\n```",
            "Do not orchestrate a workflow.",
            "Avoid uc workflow.",
            "Don't start an ultracode workflow.",
        ):
            with self.subTest(prompt=prompt):
                self.assert_silent(self.run_hook({"prompt": prompt}))

    def test_planning_verbs_select_plan_only(self):
        for prompt in (
            "plan an uc workflow",
            "outline an uc workflow",
            "design an ultracode workflow",
            "spec an uc workflow",
            "specs for an uc workflow",
            "estimate an uc workflow",
            "propose an uc workflow",
        ):
            with self.subTest(prompt=prompt):
                self.assert_plan_only(self.run_hook({"prompt": prompt}))

    def test_planning_a_build_does_not_authorize_execution(self):
        for prompt in (
            "outline a plan to build this using an uc workflow",
            "design a workflow and orchestrate a workflow to build it",
            "plan an ultracode workflow to execute the migration",
            "estimate an uc workflow to ship the application",
            "propose an uc workflow to run the checks",
            "outline an uc workflow and go through the build stages",
        ):
            with self.subTest(prompt=prompt):
                self.assert_plan_only(self.run_hook({"prompt": prompt}))

    def test_explicit_plan_and_execution_select_run(self):
        for prompt in (
            "plan and execute an uc workflow",
            "plan then run an ultracode workflow",
            "plan and build with an uc workflow",
            "PLAN AND EXECUTE AN UC WORKFLOW",
            "plan\tand\texecute an uc workflow",
        ):
            with self.subTest(prompt=prompt):
                self.assert_run(self.run_hook({"prompt": prompt}))

    def test_explicit_plan_only_or_negation_wins_over_execution(self):
        for prompt in (
            "plan only an uc workflow to build this",
            "only plan an uc workflow to execute later",
            "orchestrate a workflow, do not execute",
            "orchestrate a workflow, do not run",
            "plan and execute an uc workflow, but plan only today",
            "only plan; plan then run an uc workflow next week",
            "plan and build with an uc workflow, but do not execute",
            "plan and execute an uc workflow, but do not run anything",
            "orchestrate a workflow without executing anything",
            "orchestrate a workflow without running anything",
            "orchestrate a workflow, no execution",
            "uc workflow; don't execute",
        ):
            with self.subTest(prompt=prompt):
                self.assert_plan_only(self.run_hook({"prompt": prompt}))

    def test_runtime_plan_permission_forces_plan_only(self):
        for prompt in (
            "orchestrate a workflow",
            "execute an uc workflow",
            "plan and execute an uc workflow",
        ):
            with self.subTest(prompt=prompt):
                self.assert_plan_only(
                    self.run_hook({"prompt": prompt, "permission_mode": "plan"})
                )

    def test_word_fragments_do_not_select_plan_only(self):
        for prompt in (
            "inspect the changes with an uc workflow",
            "orchestrate a workflow for the airplane catalog",
            "orchestrate a workflow for the specification parser",
        ):
            with self.subTest(prompt=prompt):
                self.assert_run(self.run_hook({"prompt": prompt}))

    def test_empty_missing_and_null_prompts_are_silent(self):
        for payload in (
            {},
            {"prompt": None},
            {"prompt": ""},
            {"prompt": " \n\r\t "},
            {"model": "configured-codex-fixture"},
        ):
            with self.subTest(payload=payload):
                self.assert_silent(self.run_hook(payload))
        for raw in ("", " \n\r\t "):
            with self.subTest(raw=raw):
                self.assert_silent(self.run_hook(raw=raw))

    def test_malformed_or_multiple_json_documents_are_rejected(self):
        for raw in (
            "{",
            '{"prompt":',
            '{"prompt":"uc workflow",}',
            "not json",
            '{} {"prompt":"uc workflow"}',
            '{"prompt":"uc workflow"}\n{}',
        ):
            with self.subTest(raw=raw):
                self.assert_invalid(self.run_hook(raw=raw), r"json|invalid|parse")

    def test_nonobject_json_is_rejected(self):
        for payload in (None, [], ["uc workflow"], "uc workflow", True, 7):
            with self.subTest(payload=payload):
                self.assert_invalid(self.run_hook(payload), r"object|json|input")

    def test_wrong_non_null_prompt_types_are_rejected(self):
        for prompt in (True, False, 0, 1.5, [], {}, ["uc workflow"]):
            with self.subTest(prompt=prompt):
                self.assert_invalid(
                    self.run_hook({"prompt": prompt}), r"prompt|string|invalid"
                )

    def test_quotes_backslashes_and_unicode_remain_data(self):
        baseline = self.assert_run(self.run_hook({"prompt": "uc workflow"}))
        prompt = (
            'orchestrate a workflow for "quoted" and apostrophe\'s '
            'path C:\\work\\quoted\\file; café 你好 🧪\n'
        )
        context = self.assert_run(self.run_hook({"prompt": prompt}))
        self.assertEqual(context, baseline)

    def test_prompt_shell_injection_cannot_execute(self):
        with tempfile.TemporaryDirectory(prefix="hook-data-") as directory:
            marker = Path(directory) / "executed"
            for expression in (
                "$(/usr/bin/touch '" + str(marker) + "')",
                "`/usr/bin/touch '" + str(marker) + "'`",
                "'; /usr/bin/touch '" + str(marker) + "'; #",
                '\"; /usr/bin/touch \"' + str(marker) + '\"; #',
                "\n/usr/bin/touch '" + str(marker) + "'\n",
            ):
                with self.subTest(expression=expression):
                    self.assert_run(
                        self.run_hook({"prompt": "uc workflow " + expression})
                    )
                    self.assertFalse(marker.exists(), "Prompt text executed as shell")

    def test_missing_jq_is_an_actionable_failure(self):
        with tempfile.TemporaryDirectory(prefix="hook-no-jq-") as directory:
            for command in ("cat", "grep", "tr"):
                source = shutil.which(command)
                self.assertIsNotNone(source)
                (Path(directory) / command).symlink_to(source)
            result = self.run_hook(
                {"prompt": "uc workflow"}, env={"PATH": directory}
            )
            self.assert_invalid(result, r"jq")

    def test_negative_control_rejects_a_missing_required_marker(self):
        source = HOOK.read_text(encoding="utf-8")
        self.assertIn("CONTRACT FIRST", source)
        with tempfile.TemporaryDirectory(prefix="hook-negative-") as directory:
            mutated_hook = Path(directory) / "missing-contract.sh"
            mutated_hook.write_text(
                source.replace("CONTRACT FIRST", "CONTRACT OMITTED"), encoding="utf-8"
            )
            result = self.run_hook({"prompt": "uc workflow"}, path=mutated_hook)
            self.context(result)
            self.assertNotIn("CONTRACT FIRST", result.stdout)
            with self.assertRaisesRegex(AssertionError, "Missing run marker") as failure:
                self.assert_run(result)
            self.negative_controls.append(
                {
                    "mutation": "CONTRACT FIRST replaced by CONTRACT OMITTED",
                    "detected": True,
                    "assertion": str(failure.exception),
                }
            )


if __name__ == "__main__":
    unittest.main()
