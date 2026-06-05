#!/usr/bin/env python3
"""
Daydeck daily brief — GitHub Actions runner.
Fetches Google Calendar + GitHub data, generates brief with Claude, posts to Slack.
"""

import os
import json
import datetime
import requests

# ── Google Calendar ────────────────────────────────────────────────────────────

def get_google_token():
    data = {
        "client_id":     os.environ["GOOGLE_CLIENT_ID"],
        "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
        "refresh_token": os.environ["GOOGLE_REFRESH_TOKEN"],
        "grant_type":    "refresh_token",
    }
    resp = requests.post("https://oauth2.googleapis.com/token", data=data, timeout=10)
    resp.raise_for_status()
    return resp.json()["access_token"]


def fetch_calendar(token):
    now = datetime.datetime.utcnow()
    day_start = now.replace(hour=0,  minute=0,  second=0,  microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")
    day_end   = now.replace(hour=23, minute=59, second=59, microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")

    url = (
        "https://www.googleapis.com/calendar/v3/calendars/primary/events"
        f"?timeMin={day_start}&timeMax={day_end}&singleEvents=true&orderBy=startTime&maxResults=20"
    )
    resp = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=10)
    if resp.status_code != 200:
        return f"Calendar fetch failed: {resp.status_code} {resp.text[:200]}"

    events = resp.json().get("items", [])
    if not events:
        return "No calendar events today."

    lines = []
    for ev in events:
        start = ev.get("start", {}).get("dateTime", ev.get("start", {}).get("date", ""))
        end   = ev.get("end",   {}).get("dateTime", ev.get("end",   {}).get("date", ""))
        title = ev.get("summary", "(no title)")
        attendees = [a.get("displayName") or a.get("email", "") for a in ev.get("attendees", [])]
        # Trim time to HH:MM for readability
        def fmt(ts):
            if "T" in ts:
                return ts[11:16]
            return ts
        lines.append(f"  {fmt(start)}–{fmt(end)}  {title}  [{', '.join(attendees[:5])}{'...' if len(attendees) > 5 else ''}]")
    return "\n".join(lines)


# ── GitHub ─────────────────────────────────────────────────────────────────────

def fetch_github():
    token = os.environ.get("GITHUB_TOKEN", "")
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"}

    sections = []

    # PRs awaiting my review
    r = requests.get(
        "https://api.github.com/search/issues",
        params={"q": "is:pr is:open review-requested:@me", "per_page": 10},
        headers=headers, timeout=10
    )
    if r.status_code == 200:
        items = r.json().get("items", [])
        if items:
            sections.append("PRs awaiting your review:")
            for pr in items:
                sections.append(f"  #{pr['number']} {pr['title']} — {pr['repository_url'].split('/')[-1]}")
        else:
            sections.append("PRs awaiting review: none")

    # My open PRs
    r2 = requests.get(
        "https://api.github.com/search/issues",
        params={"q": "is:pr is:open author:@me", "per_page": 10},
        headers=headers, timeout=10
    )
    if r2.status_code == 200:
        items2 = r2.json().get("items", [])
        if items2:
            sections.append("Your open PRs:")
            for pr in items2:
                sections.append(f"  #{pr['number']} {pr['title']} — {pr['repository_url'].split('/')[-1]}")
        else:
            sections.append("Your open PRs: none")

    # Issues assigned to me
    r3 = requests.get(
        "https://api.github.com/search/issues",
        params={"q": "is:issue is:open assignee:@me", "per_page": 10},
        headers=headers, timeout=10
    )
    if r3.status_code == 200:
        items3 = r3.json().get("items", [])
        if items3:
            sections.append("Assigned issues:")
            for issue in items3:
                sections.append(f"  #{issue['number']} {issue['title']} — {issue['repository_url'].split('/')[-1]}")
        else:
            sections.append("Assigned issues: none")

    return "\n".join(sections) if sections else "GitHub: no data"


# ── Claude ─────────────────────────────────────────────────────────────────────

def generate_brief(calendar_data, github_data):
    import anthropic

    today = datetime.datetime.now().strftime("%A, %B %-d, %Y")

    system = """You are Daydeck, an AI daily command center. Generate a concise daily brief using EXACTLY this format:

🌅 DAYDECK — {DATE}
════════════════════════════════════════

📋 DAILY BRIEF
[2-3 sentences on key themes and urgency]

⚡ KEY ALERTS
[Bullet list of urgent items — deadlines, blocked PRs, meetings needing prep]

🎯 TOP 3 PRIORITIES
1. [Most important + why]
2. [Second]
3. [Third]

🗓️ YOUR DAY
[One line per event: HH:MM–HH:MM  Title  [key attendees]]

🐙 GITHUB
[PRs to review | Your open PRs | Assigned issues]

💡 DAY MANAGEMENT TIPS
[2-3 actionable tips based on the data]

────────────────────────────────────────
Sources: Calendar ✅ · GitHub ✅
Time window: last 24 hours

Rules:
- Only mention items that appear in the data provided
- Be specific: name meeting titles, PR numbers, people
- Skip sections that have nothing to report
- Keep the whole brief under 400 words"""

    user_content = f"""Today is {today}.

CALENDAR:
{calendar_data}

GITHUB:
{github_data}

Generate the daily brief."""

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    message = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        messages=[{"role": "user", "content": user_content}],
        system=system,
    )
    return message.content[0].text


# ── Slack ──────────────────────────────────────────────────────────────────────

def post_to_slack(text):
    webhook_url = os.environ["SLACK_WEBHOOK_URL"]
    resp = requests.post(webhook_url, json={"text": text}, timeout=10)
    if resp.status_code != 200:
        raise RuntimeError(f"Slack post failed: {resp.status_code} {resp.text}")
    print("✓ Brief sent to Slack")


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    print("Fetching Google Calendar...")
    try:
        token = get_google_token()
        calendar_data = fetch_calendar(token)
    except Exception as e:
        calendar_data = f"Calendar unavailable: {e}"
        print(f"  ⚠ {e}")

    print("Fetching GitHub...")
    try:
        github_data = fetch_github()
    except Exception as e:
        github_data = f"GitHub unavailable: {e}"
        print(f"  ⚠ {e}")

    print("Generating brief with Claude...")
    brief = generate_brief(calendar_data, github_data)
    print(brief)

    print("Posting to Slack...")
    post_to_slack(brief)


if __name__ == "__main__":
    main()
