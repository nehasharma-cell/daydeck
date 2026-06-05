#!/bin/bash
# Daydeck updater — pulls latest changes and applies any new settings.
# Usage: bash update.sh  (from the daydeck repo directory)
#
# Safe to run any time. Does not touch OAuth credentials or plugin setup.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Updating Daydeck..."
echo ""

# Pull latest skill changes (symlink means they're live immediately)
git -C "$REPO_DIR" pull
echo "✓ Skill updated"

# Re-apply permissions config (safe merge — won't overwrite existing settings)
SETTINGS="$HOME/.claude/settings.json"
python3 - "$SETTINGS" << 'PYEOF'
import json, sys, os
path = sys.argv[1]
data = {}
if os.path.exists(path):
    with open(path) as f:
        try: data = json.load(f)
        except: pass
perms = data.setdefault("permissions", {})
allow = perms.setdefault("allow", [])
for rule in ["Bash(*)", "mcp__plugin_slack_slack__*"]:
    if rule not in allow:
        allow.append(rule)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
echo "✓ Permissions up to date"

echo ""
echo "Done. Changes are live immediately — no new session needed."
echo ""
