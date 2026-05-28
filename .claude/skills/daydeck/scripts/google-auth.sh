#!/bin/bash
# Authorize gcloud Application Default Credentials with the scopes Daydeck needs.
# Run this once. Re-run if you get 403 errors from Gmail or Calendar.

set -e

echo "Authorizing Google access for Daydeck..."
echo "A browser window will open — log in and click Allow."
echo ""

gcloud auth application-default login \
  --scopes="https://www.googleapis.com/auth/cloud-platform,\
https://www.googleapis.com/auth/gmail.readonly,\
https://www.googleapis.com/auth/calendar.readonly"

echo ""
echo "Done. Run /daydeck in Claude Code to generate your daily brief."
