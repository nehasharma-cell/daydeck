---
name: daydeck
description: Generate an AI-powered daily brief from your Slack channels, Gmail, unanswered DMs, and Google Calendar — with prioritised actions and day management tips tailored to your day.
---

# Daydeck — Daily Command Center

## Overview

Pulls your Slack @mentions, unanswered DMs, Gmail, and today's calendar into a concise daily brief with AI-generated priorities and day management recommendations. Runs entirely inside Claude Code using your own credentials — no shared tokens, no central server.

---

## Requirements

At least one of the following must be configured:

**Slack** — install the official Claude Code plugin:
```bash
claude plugin install slack@claude-plugins-official --scope user
```

**Google (Gmail + Calendar)** — authorize via gcloud:
```bash
# Install gcloud if needed: https://cloud.google.com/sdk/docs/install
# Then authorize with the required scopes:
bash ~/.claude/skills/daydeck/scripts/google-auth.sh
```

---

## Step 0 — Check what's available

```bash
claude plugins list 2>&1 | grep -i "slack" && echo "SLACK=ok" || echo "SLACK=unavailable"
which gws 2>/dev/null && echo "GWS=ok" || echo "GWS=unavailable"
test -f ~/.config/gcloud/application_default_credentials.json && echo "ADC=ok" || echo "ADC=unavailable"
```

Note which services are available. Proceed with whatever is configured — at least one is needed.

---

## Step 1 — Ask for preferences

Ask the user:

> **Which Slack channels should I check?**
> Enter channel names separated by commas, or press Enter to skip channel scanning and only look at @mentions and DMs.

> **How many hours back should I look?** (default: 24)

Store the answers and use them in the steps below.

---

## Step 2 — Refresh Google token (if gws is available)

```bash
export GCLOUD_SDK_ROOT=$(gcloud info --format="value(installation.sdk_root)" 2>/dev/null)
export PYTHONPATH="$GCLOUD_SDK_ROOT/lib/third_party:$GCLOUD_SDK_ROOT/lib"

# Use the user's own GCP project — ask if not known
GCP_PROJECT=${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}
if [ -z "$GCP_PROJECT" ]; then
  echo "No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi
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

test -n "$GOOGLE_WORKSPACE_CLI_TOKEN" && echo "Google token OK" || echo "Google token FAILED — will skip Gmail/Calendar"
```

If the token fails, note it and skip Steps 4 and 5. Do not stop.

---

## Step 3 — Fetch Slack activity

**@mentions and DMs (always):**

Search for public @mentions of the current user from the last N hours:
- Use `slack_search_public` with query: `<@ME>` for the configured time window

Search for unanswered DMs:
- Use `slack_search_public_and_private` with `channel_types="im"` for the last N hours
- From the results, identify conversations where the **last message was NOT from you** — those are unanswered

**Channels (if user specified any):**
- For each channel, use `slack_read_channel` to fetch recent messages
- Summarise key discussions, decisions, and open questions

Collect:
- Threads awaiting your response
- Decisions made that affect you
- Blockers or escalations
- Unanswered DMs grouped by sender

---

## Step 4 — Fetch Gmail

```bash
gws gmail users messages list \
  --params '{"userId": "me", "q": "is:unread OR is:important newer_than:1d", "maxResults": 20}'
```

For each message ID returned, fetch metadata:

```bash
gws gmail users messages get \
  --params '{"userId": "me", "id": "MESSAGE_ID", "format": "metadata", "metadataHeaders": ["From", "Subject", "Date"]}'
```

Collect sender, subject, snippet. Note which are unread vs important. Filter out automated notifications (Jira, GitHub, calendar invites, newsletters) — flag only emails requiring a human response.

---

## Step 5 — Fetch today's calendar

```bash
TODAY_START=$(date -u +"%Y-%m-%dT00:00:00Z")
TODAY_END=$(date -u +"%Y-%m-%dT23:59:59Z")

gws calendar events list \
  --params "{\"calendarId\": \"primary\", \"timeMin\": \"$TODAY_START\", \"timeMax\": \"$TODAY_END\", \"singleEvents\": true, \"orderBy\": \"startTime\", \"maxResults\": 20}"
```

From the results note:
- Meeting titles, start/end times, and key attendees
- Any **time conflicts** (overlapping events)
- **Focus windows** — gaps of 30+ minutes between meetings
- All-day reminders or deadlines

---

## Step 6 — Generate the Daily Brief

Using all collected data, produce the output below. Every point must be grounded in actual data fetched — no generic advice.

---

```
🌅 DAYDECK — [Day, Date]
════════════════════════════════════════

📋 DAILY BRIEF
[2-3 sentences on the key themes of today]

⚡ KEY ALERTS
[Bullet list of urgent items — unanswered DMs, unread emails needing replies,
open Slack threads. Name senders, subjects, channels specifically.]

🎯 TOP 3 PRIORITIES
1. [Most important — explain why, grounded in data]
2. [Second]
3. [Third]

🗓️ YOUR DAY
[Time | Meeting | Key attendees]
[Flag conflicts with ⚠️, flag focus windows as open blocks]

💡 DAY MANAGEMENT TIPS
[3-5 specific, actionable tips based on the actual data:
calendar gaps, email urgency, DMs to batch, things to defer, things to delegate]

────────────────────────────────────────
Sources: [Slack @mentions | Slack DMs | Gmail | Calendar] — whichever were available
Time window: last [N] hours
```

---

## Notes

- All data is fetched using **your own credentials only** — Slack reads your workspace via your OAuth session, Gmail and Calendar use your own Google account via gcloud ADC.
- If only some sources are available, the brief is generated from whatever was fetched.
- To drill into any item ("show me that thread", "read that email"), use the available tools to fetch more detail.
