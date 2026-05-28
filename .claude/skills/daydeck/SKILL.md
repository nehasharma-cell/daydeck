---
name: daydeck
description: Generate an AI-powered daily brief from Slack, Gmail, Calendar, GitHub PRs, Jira, and Confluence — with prioritised actions and day management tips tailored to your day.
---

# Daydeck — Daily Command Center

## Overview

Pulls your Slack @mentions, unanswered DMs, Gmail, calendar, GitHub PRs awaiting action, Jira assignments, and Confluence mentions into a concise daily brief with AI-generated priorities and day management recommendations. Runs entirely inside Claude Code using your own credentials — no shared tokens, no central server.

---

## Requirements

Configure whichever sources you use. At least one is needed.

| Source | Setup |
|---|---|
| **Slack** | `claude plugin install slack@claude-plugins-official --scope user` |
| **Google** (Gmail + Calendar) | `bash ~/.claude/skills/daydeck/scripts/google-auth.sh` |
| **GitHub** | `gh auth login` (if not already authenticated) |
| **Jira + Confluence** | `claude mcp add atlassian` (Atlassian MCP plugin) |

---

## Step 0 — Check what's available

```bash
# Slack plugin
claude plugins list 2>&1 | grep -i slack && echo "SLACK=ok" || echo "SLACK=unavailable"

# Google
test -f ~/.config/gcloud/application_default_credentials.json && echo "GOOGLE=ok" || echo "GOOGLE=unavailable"

# GitHub CLI
gh auth status 2>&1 | grep "Logged in" && echo "GITHUB=ok" || echo "GITHUB=unavailable"

# Atlassian MCP
claude mcp list 2>&1 | grep -i atlassian && echo "ATLASSIAN=ok" || echo "ATLASSIAN=unavailable"
```

Note which are available. Skip unavailable sources gracefully — do not stop.

---

## Step 1 — Ask for preferences

Ask the user:

> **Slack channels to scan?** (comma-separated, or Enter to skip channels and only check @mentions + DMs)

> **Hours back to look?** (default: 24)

> **GitHub orgs or repos to focus on?** (e.g. `myorg`, `myorg/myrepo` — or Enter for all)

---

## Step 2 — Refresh Google token (if available)

```bash
export GCLOUD_SDK_ROOT=$(gcloud info --format="value(installation.sdk_root)" 2>/dev/null)
export PYTHONPATH="$GCLOUD_SDK_ROOT/lib/third_party:$GCLOUD_SDK_ROOT/lib"

GCP_PROJECT=${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}
export GOOGLE_WORKSPACE_PROJECT_ID=$GCP_PROJECT

export GOOGLE_WORKSPACE_CLI_TOKEN=$(python3 -c "
import google.auth
from google.auth.transport.requests import Request
scopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
]
creds, _ = google.auth.default(scopes=scopes)
if not creds.valid:
    creds.refresh(Request())
print(creds.token)
" 2>/dev/null)

test -n "$GOOGLE_WORKSPACE_CLI_TOKEN" && echo "Google token OK" || echo "Google token FAILED — skipping Gmail/Calendar"
```

---

## Step 3 — Fetch Slack activity (if available)

**@mentions:**
Use `slack_search_public` with query `<@ME>` for the configured time window.

**Unanswered DMs:**
Use `slack_search_public_and_private` with `channel_types="im"` for the last N hours.
From results, identify conversations where the **last message was not from you** — those are unanswered.

**Channels (if specified):**
Use `slack_read_channel` for each channel. Summarise key discussions, decisions, open questions.

---

## Step 4 — Fetch Gmail (if available)

```bash
gws gmail users messages list \
  --params '{"userId": "me", "q": "is:unread OR is:important newer_than:1d", "maxResults": 20}'
```

For each message, fetch metadata (From, Subject). Filter out automated notifications (Jira, GitHub bots, newsletters) — flag only emails needing a human response.

---

## Step 5 — Fetch Calendar (if available)

```bash
TODAY_START=$(date -u +"%Y-%m-%dT00:00:00Z")
TODAY_END=$(date -u +"%Y-%m-%dT23:59:59Z")

gws calendar events list \
  --params "{\"calendarId\": \"primary\", \"timeMin\": \"$TODAY_START\", \"timeMax\": \"$TODAY_END\", \"singleEvents\": true, \"orderBy\": \"startTime\", \"maxResults\": 20}"
```

Note: meeting times, attendees, conflicts (overlapping events), and focus windows (30+ min gaps).

---

## Step 6 — Fetch GitHub activity (if available)

Run all three in parallel:

```bash
# PRs awaiting your review
gh pr list \
  --search "review-requested:@me state:open" \
  --json title,url,author,createdAt,reviewDecision,additions,deletions \
  --limit 10

# PRs you authored that need attention (changes requested or review pending)
gh pr list \
  --author "@me" \
  --state open \
  --json title,url,createdAt,reviewDecision,isDraft,labels \
  --limit 10

# PRs and issues mentioning you (comments, review requests)
gh search prs \
  --mentions "@me" \
  --state open \
  --json title,url,author,createdAt,repository \
  --limit 10

# Issues assigned to you
gh issue list \
  --assignee "@me" \
  --state open \
  --json title,url,createdAt,labels,repository \
  --limit 10
```

From the results identify:
- PRs blocked on your review (especially if the author has pinged you)
- Your own PRs with changes requested or stale (no activity in 2+ days)
- Issues due or urgent based on labels

---

## Step 7 — Fetch Jira activity (if Atlassian MCP available)

Use the Atlassian MCP tools to:

**Issues assigned to you:**
Search Jira for issues assigned to the current user with status not Done:
```
assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC
```
Fetch up to 15 results. Note ticket key, summary, status, priority, and due date.

**Recent @mentions:**
Search for issues where you were mentioned in comments in the last 2 days:
```
issueFunction in commented("by currentUser()") AND updated >= -2d
```
Note any that have open questions directed at you.

**Blocked or urgent items:**
Look for issues with priority Highest/High, or labels like `blocked`, `urgent`, `needs-input`.

---

## Step 8 — Fetch Confluence mentions (if Atlassian MCP available)

Use the Atlassian MCP tools to search Confluence for:

- Pages where you were **@mentioned** in the last 2 days
- Pages you are listed as **owner or contributor** that were recently updated
- Any pages with open **comments or tasks assigned to you**

Summarise the page title, space, who mentioned you, and what action (if any) is needed.

---

## Step 9 — Generate the Daily Brief

Synthesise everything collected and produce the output below. Every point must be grounded in actual fetched data. Filter out noise (bot notifications, automated Jira transitions, FYI-only emails).

```
🌅 DAYDECK — [Day, Date]
════════════════════════════════════════

📋 DAILY BRIEF
[2-3 sentences capturing the key themes and any dominant urgency]

⚡ KEY ALERTS
[Bulleted list — unanswered DMs, PRs needing review, Jira items
with deadlines or blockers, emails needing a human reply.
Name senders, PR titles, ticket keys, Confluence pages specifically.]

🎯 TOP 3 PRIORITIES
1. [Most important — state what and why, grounded in data]
2. [Second]
3. [Third]

🗓️ YOUR DAY
[HH:MM–HH:MM  Meeting title  [key attendees]]
[Flag ⚠️ for conflicts, mark open gaps as focus windows]

💬 SLACK
[Key @mentions and unanswered DMs needing a reply]

📧 EMAIL
[Emails needing a human response — skip bot/automated mail]

🐙 GITHUB
[PRs awaiting your review | Your PRs with changes requested | Assigned issues]

📋 JIRA
[Assigned tickets by priority | Recent @mentions needing a response]

📄 CONFLUENCE
[Pages where you were mentioned | Open tasks assigned to you]

💡 DAY MANAGEMENT TIPS
[3-5 specific, actionable tips based on the actual data:
when to review PRs, how to batch Slack/email, what to defer,
calendar gaps to protect for focus work]

────────────────────────────────────────
Sources: [list which were available and fetched]
Time window: last [N] hours
```

---

## Notes

- **Your data only.** All sources use your own OAuth/credentials. Nothing is shared.
- **Graceful degradation.** Missing sources are skipped; the brief is generated from whatever was fetched.
- **Drill down.** After the brief, ask Claude to expand any section: *"Show me that PR"*, *"Read that Jira ticket"*, *"What did they say in that Slack thread?"*
