#!/usr/bin/env bash
# Write fresh.json: the last-pushed date of every repo pinned in index.html.
# The page reads this file from Pages instead of calling the GitHub API from each visitor's browser.
# Needs: gh (with GH_TOKEN) and jq. Leaves fresh.json untouched when no date has changed.
set -euo pipefail
OWNER="${OWNER:-dougbristor}"
cd "$(dirname "$0")/.."
repos=$(grep -o 'repo: "[^"]*"' index.html | sed 's/repo: "\(.*\)"/\1/')
[ -n "$repos" ] || { echo "no repos found in index.html" >&2; exit 1; }
obj='{}'
for r in $repos; do
  d=$(gh api "repos/$OWNER/$r" --jq .pushed_at)
  [ -n "$d" ] || { echo "no date for $r" >&2; exit 1; }
  obj=$(jq --arg r "$r" --arg d "$d" '. + {($r): $d}' <<<"$obj")
done
old='null'; [ -f fresh.json ] && old=$(jq -c '.repos' fresh.json)
if [ "$old" = "$(jq -c . <<<"$obj")" ]; then echo "no change"; exit 0; fi
jq -n --arg g "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson repos "$obj" '{generated: $g, repos: $repos}' > fresh.json
echo "fresh.json updated:"; cat fresh.json
