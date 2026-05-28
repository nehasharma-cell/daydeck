# Daydeck

An AI-powered daily command center for Claude Code.

Type `/daydeck` and Claude fetches your Slack @mentions, unanswered DMs, Gmail, calendar, GitHub PRs, Jira assignments, and Confluence mentions — then tells you exactly what to focus on and how to manage your day.

Everything runs locally using **your own credentials**. No data is sent to any central server.

---

## What you get

```
🌅 DAYDECK — Thursday, May 28

📋 DAILY BRIEF
You have 2 PRs awaiting review, a Jira ticket blocked on your input,
and 3 unanswered DMs from yesterday. Calendar is back-to-back from 10–16.

⚡ KEY ALERTS
- PR #1823 "Add rate limiting" — review requested by Alex, 3 days old
- PROJ-412 blocked on your decision — Priya mentioned you in comments
- Unanswered DM from Sam re: Q3 roadmap (last night)
- Email from Legal re: contract — deadline today

🎯 TOP 3 PRIORITIES
1. Review PR #1823 — Alex is blocked, it's been 3 days
2. Reply to PROJ-412 — Priya needs your call to unblock the sprint
3. Reply to Sam's DM — it's about the Q3 roadmap sync you scheduled

🗓️ YOUR DAY
10:00–11:00  Weekly sync          [alex, priya, sam]
11:00–11:30  Team standup         [you're organiser]
11:30–12:30  ⚠️ CONFLICT          All Hands OR Design Review
14:00–15:00  ░░ Focus window ░░

💬 SLACK      3 unanswered DMs · 2 channel @mentions
📧 EMAIL      1 email needing reply (Legal)
🐙 GITHUB     2 PRs to review · 1 of your PRs has changes requested
📋 JIRA       4 open assigned tickets · 1 mention needing input
📄 CONFLUENCE 1 page where you were @mentioned yesterday

💡 DAY MANAGEMENT TIPS
- Review PR #1823 in the 14:00 focus window — it's a focused task
- Batch the 3 DM replies before your 10:00 meeting (5 min total)
- Resolve the 11:30 conflict now so you're not scrambling mid-standup
```

---

## Install

```bash
git clone https://github.com/nehasharma-cell/daydeck.git
cd daydeck
bash install.sh
```

The installer symlinks the skill to `~/.claude/skills/daydeck` — available in every Claude Code session. Updates via `git pull` are picked up automatically.

---

## Setup

Connect whichever tools you use. Each one is optional — Daydeck works with whatever is available.

### Slack
```bash
claude plugin install slack@claude-plugins-official --scope user
```
Browser OAuth sign-in on first use. No tokens to manage.

### Google (Gmail + Calendar)
Requires [Google Cloud SDK](https://cloud.google.com/sdk/docs/install).
```bash
bash ~/.claude/skills/daydeck/scripts/google-auth.sh
gcloud config set project YOUR_GCP_PROJECT_ID
```

### GitHub
```bash
gh auth login   # if not already authenticated
```
Uses your existing `gh` CLI session. No extra setup if you already use `gh`.

### Jira + Confluence
Requires the Atlassian MCP plugin for Claude Code:
```bash
claude mcp add atlassian
```
Follow the OAuth prompt to connect your Atlassian account.

---

## Usage

In any Claude Code session:
```
/daydeck
```

Claude asks which Slack channels to scan (optional) and how far back to look (default 24h), then fetches everything and produces your brief.

Follow-up questions work too:
- *"Show me that PR"*
- *"Read the email from Legal"*
- *"What did Priya say in that Jira ticket?"*
- *"Summarise that Confluence page"*

---

## Sources

| Source | What Daydeck fetches |
|---|---|
| **Slack** | @mentions in channels · unanswered DMs · channel activity |
| **Gmail** | Unread and important emails needing a human reply |
| **Google Calendar** | Today's meetings · conflicts · focus windows |
| **GitHub** | PRs awaiting your review · your open PRs · assigned issues |
| **Jira** | Assigned tickets · @mentions in comments · blocked/urgent items |
| **Confluence** | Pages where you were @mentioned · open tasks assigned to you |

---

## Privacy

- **Your data stays on your machine.** Each source uses your own OAuth credentials.
- **No data is stored or logged.** Claude processes everything in memory for your session only.
- **No central server.** The skill is a set of instructions that runs inside your local Claude Code instance.

---

## Update

```bash
cd daydeck && git pull
```

Symlinks mean updates are live immediately — no reinstall needed.

---

## Requirements

- [Claude Code](https://claude.ai/code)
- One or more sources configured (Slack, Google, GitHub, Atlassian)
