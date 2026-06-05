#!/bin/bash
# Daydeck installer — makes /daydeck available in all Claude Code sessions.
# Usage: bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$REPO_DIR/.claude/skills/daydeck"
SKILL_DST="$HOME/.claude/skills/daydeck"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║        Installing Daydeck 🌅          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Preflight ──────────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "✗ Claude Code not found. Install it from https://claude.ai/code"
  exit 1
fi

# ── Skill symlink ──────────────────────────────────────────────────────────
mkdir -p "$HOME/.claude/skills"
if [ -e "$SKILL_DST" ]; then
  rm -rf "$SKILL_DST"
fi
ln -s "$SKILL_SRC" "$SKILL_DST"
echo "✓ Skill installed (~/.claude/skills/daydeck)"

# ── Permissions (no-prompt runs) ───────────────────────────────────────────
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
echo "✓ Permissions configured (no prompts on run)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setting up data sources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Slack (default) ────────────────────────────────────────────────────────
echo ""
echo "▸ Slack (included by default)"
if claude plugin install slack@claude-plugins-official --scope user 2>/dev/null; then
  echo "  ✓ Slack plugin installed — a browser window will open for sign-in on first use"
else
  echo "  ✓ Slack plugin already installed"
fi

# ── Google / Gmail + Calendar (default) ───────────────────────────────────
echo ""
echo "▸ Google — Gmail + Calendar (included by default)"
if command -v gcloud &>/dev/null; then
  echo "  A browser window will open — sign in and click Allow."
  bash "$SKILL_SRC/scripts/google-auth.sh"
  echo ""
  echo "  GCP project is needed to activate the Google Workspace API."
  read -rp "  Enter your GCP project ID (or press Enter to skip): " GCP_PROJECT
  if [ -n "$GCP_PROJECT" ]; then
    gcloud config set project "$GCP_PROJECT"
    echo "  ✓ GCP project set to $GCP_PROJECT"
  else
    echo "  ⚠ Skipped — run: gcloud config set project YOUR_PROJECT_ID"
  fi
else
  echo "  ⚠ gcloud not found. Install Google Cloud SDK to enable Gmail + Calendar."
  echo "    https://cloud.google.com/sdk/docs/install"
  echo "    Then run: bash ~/.claude/skills/daydeck/scripts/google-auth.sh"
fi

# ── Optional sources ───────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Optional sources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# GitHub
echo ""
read -rp "▸ GitHub (PRs, issues, mentions)? [y/N] " ADD_GITHUB
if [[ "$ADD_GITHUB" =~ ^[Yy]$ ]]; then
  if command -v gh &>/dev/null; then
    gh auth login
    echo "  ✓ GitHub connected"
  else
    echo "  ⚠ gh CLI not found. Install from https://cli.github.com then run: gh auth login"
  fi
else
  echo "  Skipped — run 'gh auth login' any time to add it later"
fi

# Jira + Confluence
echo ""
read -rp "▸ Jira + Confluence (tickets, mentions)? [y/N] " ADD_ATLASSIAN
if [[ "$ADD_ATLASSIAN" =~ ^[Yy]$ ]]; then
  claude mcp add atlassian
  echo "  ✓ Atlassian MCP configured"
else
  echo "  Skipped — run 'claude mcp add atlassian' any time to add it later"
fi

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Daydeck is ready ✓"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Start a new Claude Code session and ask:"
echo "    How is my day?"
echo "  or type:"
echo "    /daydeck"
echo ""
echo "  To update later: cd $REPO_DIR && git pull"
echo ""
