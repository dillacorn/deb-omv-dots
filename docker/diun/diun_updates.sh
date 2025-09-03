#!/usr/bin/env bash
# diun_updates.sh
#
# Show a clean, deduplicated list of Docker applications that CAN be updated,
# based on Diun logs ("New image found" entries).
#
# Output file: output_update_list.txt
# Output columns: Maker | App | Tags (compact, no giant spacing)

set -euo pipefail

CONTAINER="${1:-diun}"
SINCE="${2:-}"           # optional: e.g. 24h or RFC3339 timestamp
OUTFILE="./output_update_list.txt"

# Pull logs
if [[ -n "$SINCE" ]]; then
  LOGS="$(docker logs --since "$SINCE" "$CONTAINER" 2>&1 || true)"
else
  LOGS="$(docker logs "$CONTAINER" 2>&1 || true)"
fi

# Extract only "New image found" lines and pull the image reference
IMAGES="$(printf '%s\n' "$LOGS" | grep -i 'New image found' | sed -n 's/.*image=\([^ ]*\).*/\1/p' | sort -u || true)"

if [[ -z "$IMAGES" ]]; then
  printf 'No Docker applications currently CAN be updated (no "New image found" entries in Diun logs).\n' | tee "$OUTFILE"
  exit 0
fi

# Transform refs into Maker, App, Tag; drop digests; aggregate tags by Maker/App
REPORT="$(printf '%s\n' "$IMAGES" | awk '
  function rm_digest(s) {
    gsub(/@sha256:[0-9a-f]{64}/, "", s)
    return s
  }
  function add_tag(key, tag) {
    if (key in tags_seen) {
      n = split(tags_seen[key], arr, ",")
      found = 0
      for (i=1; i<=n; i++) if (arr[i] == tag) { found = 1; break }
      if (!found) tags_seen[key] = tags_seen[key] "," tag
    } else {
      tags_seen[key] = tag
    }
  }
  {
    img = rm_digest($0)
    n = split(img, p, "/")
    if (n == 1) {
      maker = "library"
      last  = p[1]
    } else {
      maker = (n >= 2 ? p[n-1] : "library")
      last  = p[n]
    }
    repo = last
    tag  = "latest"
    m = index(last, ":")
    if (m > 0) {
      repo = substr(last, 1, m-1)
      tag  = substr(last, m+1)
    }
    key = maker "/" repo
    add_tag(key, tag)
  }
  END {
    for (k in tags_seen) {
      split(k, a, "/")
      maker = a[1]; app = a[2]; tags = tags_seen[k]
      printf "%s|%s|%s\n", maker, app, tags
    }
  }
' | sort -f )"

# Write simple, compact table
{
  printf '=== Docker Applications That CAN Be Updated (Diun Report %s) ===\n\n' "$(date)"
  printf 'Maker|App|Tags\n'
  printf '%s\n' "$REPORT"
} | tee "$OUTFILE"
