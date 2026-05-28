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
