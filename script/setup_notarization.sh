#!/usr/bin/env bash
# Run interactively in Terminal. Password entry is owned by Apple's notarytool.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="WakeBee-Notary"
TEAM_ID="B88SZ4A65M"

echo "Set up Apple notarization for WakeBee"
echo "Use the Apple Developer account for team $TEAM_ID."
echo "Create an app-specific password at https://account.apple.com under Sign-In and Security."
echo "Paste it only into Apple's hidden password prompt below, never into chat."
echo
read -r -p "Apple Developer email: " NOTARY_APPLE_ID
[[ -n "$NOTARY_APPLE_ID" ]] || { echo "An Apple Developer email is required." >&2; exit 1; }
xcrun notarytool store-credentials "$PROFILE" --apple-id "$NOTARY_APPLE_ID" --team-id "$TEAM_ID"
# A newly stored WakeBee credential no longer needs the legacy local alias.
python3 - "$ROOT_DIR/.notary-profile-aliases.json" "$PROFILE" <<'PYTHON'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
if path.exists():
    aliases = json.loads(path.read_text())
    aliases.pop(sys.argv[2], None)
    path.write_text(json.dumps(aliases, indent=2) + "\n")
PYTHON
printf '%s\n' "$PROFILE" > "$ROOT_DIR/.notary-profile"
echo
echo "Notarization credentials validated and saved in Keychain. You can return to the release workflow."
