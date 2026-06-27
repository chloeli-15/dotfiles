#!/usr/bin/env python3
"""Claude Code Notification hook → ntfy.sh phone push. Reads the hook JSON on stdin and pushes
Claude Code's notification message, with the session's project (cwd basename) in the title.
Never fails loudly (a hook error must not disrupt the session). Repo-agnostic + stdlib-only, so
it works in any repo on any machine with python3 + outbound HTTPS. Topic via CLAUDE_NTFY_TOPIC."""
import sys
import os
import json
import urllib.request

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

msg = d.get("message") or "Claude Code is waiting for your input"
proj = os.path.basename((d.get("cwd") or "").rstrip("/")) or "?"
topic = os.environ.get("CLAUDE_NTFY_TOPIC", "talkie-chloel-0d10764a8")

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
