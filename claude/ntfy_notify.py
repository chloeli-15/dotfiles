#!/usr/bin/env python3
"""Claude Code hook -> ntfy.sh phone push. Handles two hook events (dispatched by JSON shape):

  PreToolUse / AskUserQuestion : RELIABLE ping whenever the agent poses a question (body = the
                                 question text). This is the dependable "needs your input" signal.
  Notification                 : ping on actionable notifications (e.g. permission prompts); the
                                 idle "waiting for your input" message is filtered out as noise.

Title carries the project (cwd basename) + tmux window if present. Repo-agnostic, stdlib-only,
never fails loudly (a hook error must not disrupt the session). Topic via CLAUDE_NTFY_TOPIC;
CLAUDE_NTFY_ALL=1 disables the idle filter."""
import sys
import os
import time
import json
import subprocess
import urllib.request

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

proj = os.path.basename((d.get("cwd") or "").rstrip("/")) or "?"
topic = os.environ.get("CLAUDE_NTFY_TOPIC", "talkie-chloel-0d10764a8")


def tmux_suffix():
    if not os.environ.get("TMUX"):
        return ""
    try:
        w = subprocess.run(["tmux", "display-message", "-p", "#W #I"],
                           capture_output=True, text=True, timeout=3).stdout.strip()
        return f" · {w}" if w else ""
    except Exception:
        return ""


tool = d.get("tool_name")
if tool == "AskUserQuestion":                       # PreToolUse: a question is being posed
    qs = (d.get("tool_input") or {}).get("questions") or []
    first = (qs[0].get("question") if qs else "") or "Claude is asking you a question"
    body = f"({len(qs)} questions) {first}" if len(qs) > 1 else first
    title, tag = f"{proj}{tmux_suffix()} · question", "question"
else:                                               # Notification event
    msg = d.get("message") or ""
    try:
        with open(os.path.expanduser("~/.claude/hooks/ntfy_notify.log"), "a") as f:
            f.write(f"{time.strftime('%F %T')}\t{proj}\t{msg}\n")
    except Exception:
        pass
    if not os.environ.get("CLAUDE_NTFY_ALL") and (not msg or "waiting for your input" in msg.lower()):
        sys.exit(0)                                 # idle ping = noise; skip
    body, title, tag = msg, f"{proj}{tmux_suffix()} · Claude needs you", "robot"

try:
    urllib.request.urlopen(urllib.request.Request(
        f"https://ntfy.sh/{topic}", data=body.encode("utf-8"),
        headers={"Title": title, "Tags": tag, "Priority": "high"}, method="POST"), timeout=10).read()
except Exception:
    pass
