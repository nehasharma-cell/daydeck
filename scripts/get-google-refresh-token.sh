#!/bin/bash
# Extracts Google OAuth credentials from your local gcloud ADC file.
# Run this once on your Mac, then paste the output into GitHub Secrets.
#
# Usage: bash scripts/get-google-refresh-token.sh

set -e

ADC="$HOME/.config/gcloud/application_default_credentials.json"

if [ ! -f "$ADC" ]; then
  echo "✗ File not found: $ADC"
  echo "  Run: gcloud auth application-default login"
  exit 1
fi

CLIENT_ID=$(python3 -c "import json; d=json.load(open('$ADC')); print(d.get('client_id',''))")
CLIENT_SECRET=$(python3 -c "import json; d=json.load(open('$ADC')); print(d.get('client_secret',''))")
REFRESH_TOKEN=$(python3 -c "import json; d=json.load(open('$ADC')); print(d.get('refresh_token',''))")

if [ -z "$REFRESH_TOKEN" ]; then
  echo "✗ No refresh_token found in $ADC"
  echo "  Run: gcloud auth application-default login --scopes=https://www.googleapis.com/auth/calendar.readonly,https://www.googleapis.com/auth/gmail.readonly,https://www.googleapis.com/auth/cloud-platform"
  exit 1
fi

echo ""
echo "Copy these into your GitHub repo → Settings → Secrets → Actions:"
echo ""
echo "GOOGLE_CLIENT_ID"
echo "  $CLIENT_ID"
echo ""
echo "GOOGLE_CLIENT_SECRET"
echo "  $CLIENT_SECRET"
echo ""
echo "GOOGLE_REFRESH_TOKEN"
echo "  $REFRESH_TOKEN"
echo ""
