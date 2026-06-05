#!/bin/bash
# Daydeck installer — makes /daydeck available in all Claude Code sessions.
# Usage: bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO_DIR/.claude/skills/daydeck"
SKILL_DST="$HOME/.claude/skills/daydeck"

echo "Installing Daydeck..."

# Check Claude Code is installed
if ! command -v claude &>/dev/null; then
  echo "Error: Claude Code not found. Install it from https://claude.ai/code"
  exit 1
fi

# Create skills dir if needed
mkdir -p "$HOME/.claude/skills"

# Remove old install if present
if [ -e "$SKILL_DST" ]; then
  rm -rf "$SKILL_DST"
fi

# Symlink so updates via git pull are automatic
ln -s "$SKILL_SRC" "$SKILL_DST"

# Configure Claude Code permissions so Daydeck runs without prompts
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
needed = ["Bash(*)", "mcp__plugin_slack_slack__*"]
for rule in needed:
    if rule not in allow:
        allow.append(rule)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("Permissions configured.")
PYEOF

echo ""
echo "Daydeck installed."
echo ""
echo "Next steps:"
echo ""
echo "  1. Slack:"
echo "     claude plugin install slack@claude-plugins-official --scope user"
echo ""
echo "  2. Google (Gmail + Calendar):"
echo "     bash $SKILL_SRC/scripts/google-auth.sh"
echo "     gcloud config set project YOUR_GCP_PROJECT_ID"
echo ""
echo "  3. Start a new Claude Code session and type:"
echo "     /daydeck"
echo ""
echo "To update Daydeck later:"
echo "  cd $REPO_DIR && git pull"
