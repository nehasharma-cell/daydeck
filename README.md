# Daydeck

An AI-powered daily command center for Claude Code.

Type `/daydeck` and Claude fetches your Slack @mentions, unanswered DMs, Gmail, and today's calendar — then tells you what to focus on and how to manage your day.

Everything runs locally using **your own credentials**. No data is sent to any central server.

---

## What you get

```
🌅 DAYDECK — Thursday, May 28

📋 DAILY BRIEF
Three sentences on the key themes of your day.

⚡ KEY ALERTS
- Unanswered DM from Alex re: Q3 planning (sent last night)
- Unread email from Legal re: contract review — deadline today
- Open thread in #product waiting for your input

🎯 TOP 3 PRIORITIES
1. Reply to Alex — he's blocked on your decision
2. Resolve the 11:30 calendar conflict before your standup
3. Send the contract feedback — deadline is EOD

🗓️ YOUR DAY
10:00–11:00  Weekly sync  [alex, priya, sam]
11:00–11:30  Team standup  [you're organiser]
11:30–12:30  ⚠️ CONFLICT — All Hands or Design Review
...

💡 DAY MANAGEMENT TIPS
- Reply to the 3 unanswered DMs before 10:00 — all are quick
- Block 14:00–15:00 for focused work (your only gap today)
- Defer the roadmap doc to tomorrow — nothing is blocked on it today
```

---

## Install

```bash
git clone https://github.com/YOUR_USERNAME/daydeck.git
cd daydeck
bash install.sh
```

The installer symlinks the skill to `~/.claude/skills/daydeck` so it's available in every Claude Code session. Updates via `git pull` are picked up automatically.

---

## Setup

### Slack

```bash
claude plugin install slack@claude-plugins-official --scope user
```

First time you use a Slack tool, your browser opens for OAuth sign-in. After that it's automatic.

### Google (Gmail + Calendar)

Requires [Google Cloud SDK](https://cloud.google.com/sdk/docs/install).

```bash
# Authorize with Gmail + Calendar scopes
bash ~/.claude/skills/daydeck/scripts/google-auth.sh

# Set your GCP project
gcloud config set project YOUR_PROJECT_ID
```

If you don't have a GCP project, create a free one at [console.cloud.google.com](https://console.cloud.google.com). No billing needed for Gmail/Calendar read access.

---

## Usage

In any Claude Code session:

```
/daydeck
```

Claude will ask which Slack channels to scan (optional) and how many hours back to look (default 24h), then fetch everything and produce your brief.

You can also ask follow-up questions:
- *"Show me that Slack thread"*
- *"Read the email from Legal"*
- *"What's on my calendar tomorrow?"*

---

## Privacy

- **Your data stays on your machine.** Daydeck reads your Slack, Gmail, and Calendar using your own OAuth sessions — the same credentials you use normally.
- **No data is stored or logged.** Claude processes it in memory for your session only.
- **No central server.** The skill is a set of instructions that runs inside your local Claude Code instance.

---

## Update

```bash
cd daydeck
git pull
```

Symlinks mean the update is live immediately — no reinstall needed.

---

## Requirements

- [Claude Code](https://claude.ai/code)
- Slack plugin (for Slack features)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) + [gws CLI](https://github.com/nicholasgasior/gws) (for Gmail/Calendar)
