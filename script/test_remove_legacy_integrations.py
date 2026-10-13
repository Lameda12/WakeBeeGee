import unittest
from remove_legacy_integrations import MARKER, MARKERS, RETIRED_BRIDGE, remove_hooks
import subprocess


class CleanupTests(unittest.TestCase):
    def test_removes_current_and_legacy_hooks_together(self):
        source = {"hooks": {"Stop": [{"hooks": [{"command": "run " + marker} for marker in MARKERS]}]}}
        self.assertEqual(remove_hooks(source), ({"hooks": {}}, 2))

    def test_preserves_unrelated_current_hook_group(self):
        keep = {"command": "my-tool", "timeout": 42}
        source = {"hooks": {"Stop": [{"matcher": "x", "hooks": [keep, {"command": "run " + MARKERS[1]}]}]}}
        result, count = remove_hooks(source)
        self.assertEqual(count, 1)
        self.assertEqual(result["hooks"]["Stop"], [{"matcher": "x", "hooks": [keep]}])

    def test_retired_bridge_returns_neutral_json(self):
        result = subprocess.run(["/bin/sh", "-c", RETIRED_BRIDGE.decode()],
                                input=b'{"sensitive_prompt":"discard"}', capture_output=True, check=True)
        self.assertEqual(result.stdout, b"{}\n")
        self.assertEqual(result.stderr, b"")

    def test_preserves_other_commands_matchers_and_preferences(self):
        custom = {"type": "command", "command": "echo keep", "timeout": 9}
        source = {"preference": {"enabled": True}, "hooks": {"Stop": [
            {"matcher": "custom", "hooks": [custom, {"command": "echo done " + MARKER}]}
        ]}}
        result, count = remove_hooks(source)
        self.assertEqual(count, 1)
        self.assertEqual(result, {"preference": {"enabled": True}, "hooks": {"Stop": [
            {"matcher": "custom", "hooks": [custom]}
        ]}})
        self.assertEqual(len(source["hooks"]["Stop"][0]["hooks"]), 2)

    def test_removes_owned_direct_and_grouped_hooks(self):
        source = {"version": 1, "hooks": {
            "start": [{"bash": "run " + MARKER}],
            "stop": [{"hooks": [{"command": "run " + MARKER}]}],
            "other": [{"command": "echo leave this alone"}],
        }}
        result, count = remove_hooks(source)
        self.assertEqual(count, 2)
        self.assertEqual(result, {"version": 1, "hooks": {"other": [{"command": "echo leave this alone"}]}})

    def test_similar_text_is_not_owned(self):
        source = {"hooks": {"Stop": [{"command": "echo '" + MARKER + "'"}]}}
        self.assertEqual(remove_hooks(source), (source, 0))

    def test_second_cleanup_is_unchanged(self):
        result, _ = remove_hooks({"hooks": {"Stop": [{"command": "run " + MARKER}]}})
        self.assertEqual(remove_hooks(result), (result, 0))

    def test_rejects_unknown_structure(self):
        for source in ([], {"hooks": []}, {"hooks": {"Stop": "custom"}}):
            with self.assertRaises(ValueError):
                remove_hooks(source)


if __name__ == "__main__":
    unittest.main()
