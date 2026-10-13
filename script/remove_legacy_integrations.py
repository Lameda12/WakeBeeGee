#!/usr/bin/env python3
"""Remove AwakeMac task hooks, preserving exact backups and other settings."""
import argparse
import copy
import json
import os
from pathlib import Path
import stat
import tempfile
import uuid

MARKER = "# awakemac:v1"
MARKERS = (MARKER, "# awakemac:activity:v2")
JSON_PATHS = (
    ".claude/settings.json", ".codex/hooks.json", ".gemini/settings.json",
    ".cursor/hooks.json", ".copilot/hooks/awakemac.json",
)
PLUGIN_PATH = ".config/opencode/plugins/awakemac.js"
BRIDGE_PATHS = ("Library/Application Support/AwakeMac/bin/awakemac-hook",
                "Library/Application Support/AwakeMac/bin/awakemac-activity")
# Already-open agents may cache the old command until they restart. Drain stdin
# and return a neutral response without monitoring any work or requesting power.
RETIRED_BRIDGE = b"#!/bin/sh\n# AwakeMac retired integration: safe for cached hooks.\n/bin/cat > /dev/null\nprintf '{}\\n'\n"


def remove_hooks(original):
    if not isinstance(original, dict):
        raise ValueError("Expected a JSON object; left unchanged")
    root = copy.deepcopy(original)
    if "hooks" not in root:
        return root, 0
    hooks = root["hooks"]
    if not isinstance(hooks, dict):
        raise ValueError("Unsupported hooks structure; left unchanged")
    removed = 0

    def owned(entry):
        return any(isinstance(entry.get(key), str) and entry[key].endswith(MARKERS)
                   for key in ("command", "bash"))

    for event, entries in list(hooks.items()):
        if not isinstance(entries, list) or not all(isinstance(e, dict) for e in entries):
            raise ValueError("Unsupported hook entries; left unchanged")
        retained = []
        for entry in entries:
            if owned(entry):
                removed += 1
                continue
            children = entry.get("hooks")
            if isinstance(children, list) and all(isinstance(c, dict) for c in children):
                kept = [child for child in children if not owned(child)]
                removed += len(children) - len(kept)
                if children and not kept:
                    continue
                entry["hooks"] = kept
            retained.append(entry)
        if retained:
            hooks[event] = retained
        else:
            # Leave an unrelated empty event untouched.
            if entries:
                del hooks[event]
    return root, removed


def read_owned_file(path, maximum=4_194_304):
    if path.resolve() != path:
        raise ValueError(f"Symbolic-link path left unchanged: {path}")
    if not path.exists():
        return None
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_nlink != 1:
        raise ValueError(f"Unexpected file ownership or type: {path}")
    if info.st_size > maximum:
        raise ValueError(f"File too large: {path}")
    return path.read_bytes()


def save_change(path, previous, replacement):
    if read_owned_file(path, max(len(previous), 4_194_304)) != previous:
        raise ValueError(f"Configuration changed during cleanup: {path}")
    backup = path.with_name(path.name + ".awakemac-backup-" + uuid.uuid4().hex)
    descriptor = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "wb") as file:
        file.write(previous)
        file.flush()
        os.fsync(file.fileno())
    if read_owned_file(path, max(len(previous), 4_194_304)) != previous:
        raise ValueError(f"Configuration changed; backup retained: {path}")
    if replacement is None:
        path.unlink()
    else:
        descriptor, temporary = tempfile.mkstemp(prefix=".awakemac-cleanup-", dir=path.parent)
        try:
            with os.fdopen(descriptor, "wb") as file:
                file.write(replacement)
                file.flush()
                os.fsync(file.fileno())
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    print(f"Updated {path}\nBackup: {backup}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Apply cleanup; defaults to a read-only preview")
    args = parser.parse_args()
    home = Path.home()
    changes = []
    for relative in JSON_PATHS:
        path = home / relative
        previous = read_owned_file(path)
        if previous is None or not any(marker.encode() in previous for marker in MARKERS):
            continue
        updated, count = remove_hooks(json.loads(previous))
        if count:
            changes.append((path, previous, (json.dumps(updated, indent=2, ensure_ascii=False) + "\n").encode()))
            print(f"Remove {count} AwakeMac hook(s): {path}")
    plugin = home / PLUGIN_PATH
    previous = read_owned_file(plugin)
    if previous is not None and previous.startswith(b"// AwakeMac managed integration v1"):
        changes.append((plugin, previous, None))
        print(f"Remove managed AwakeMac plugin: {plugin}")
    for relative in BRIDGE_PATHS:
        bridge = home / relative
        previous = read_owned_file(bridge, 100_000_000)
        if previous is not None and previous != RETIRED_BRIDGE:
            changes.append((bridge, previous, RETIRED_BRIDGE))
            print(f"Retire AwakeMac hook executable: {bridge}")
    if args.apply:
        for change in changes:
            save_change(*change)
            if change[2] == RETIRED_BRIDGE:
                change[0].chmod(0o700)
    elif changes:
        print("Preview only. Use --apply to save backups and apply these changes.")
    else:
        print("No legacy AwakeMac integrations found.")


if __name__ == "__main__":
    main()
