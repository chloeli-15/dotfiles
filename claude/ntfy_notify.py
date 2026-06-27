#!/usr/bin/env python3
"""Claude Code Notification hook → ntfy.sh phone push. Reads the hook JSON on stdin and pushes
Claude Code's notification message, with the session's project (cwd basename) in the title.
Never fails loudly (a hook error must not disrupt the session). Repo-agnostic + stdlib-only, so
it works in any repo on any machine with python3 + outbound HTTPS. Topic via CLAUDE_NTFY_TOPIC."""
import sys
import os
import time
import json
import urllib.request

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

msg = d.get("message") or ""
proj = os.path.basename((d.get("cwd") or "").rstrip("/")) or "?"
topic = os.environ.get("CLAUDE_NTFY_TOPIC", "talkie-chloel-0d10764a8")

# Log every notification (so the filter can be tuned from real data).
try:
    with open(os.path.expanduser("~/.claude/hooks/ntfy_notify.log"), "a") as _f:
        _f.write(f"{time.strftime('%F %T')}\t{proj}\t{msg}\n")
except Exception:
    pass

# Skip the idle "waiting for your input" notification — it fires ~60s after a turn ends even when
# you're actively reading, and nothing is actually prompting. Only push for actionable prompts
# (permission/approval). Set CLAUDE_NTFY_ALL=1 to push on every notification instead.
if not os.environ.get("CLAUDE_NTFY_ALL"):
    if not msg or "waiting for your input" in msg.lower():
        sys.exit(0)

req = urllib.request.Request(
    f"https://ntfy.sh/{topic}",
    data=msg.encode("utf-8"),
    headers={"Title": f"{proj} · Claude needs you", "Tags": "robot", "Priority": "high"},
    method="POST",
)
try:
    urllib.request.urlopen(req, timeout=10).read()
except Exception:
    pass
