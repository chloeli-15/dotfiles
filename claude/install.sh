#!/usr/bin/env bash
# Wire the Claude Code -> ntfy.sh push-notification hook into ~/.claude on THIS machine.
# Run once per node/cluster (~/.claude is per-node-local on the fellows cluster). Idempotent and
# safe to re-run; re-running also updates the topic.
#
#   ./install.sh [ntfy-topic]      # default topic: talkie-chloel-0d10764a8
#
# Pushes a phone alert whenever any Claude Code session needs your input (permission prompt or
# idle), titled "<project> · Claude needs you". Needs python3 + outbound HTTPS to ntfy.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
TOPIC="${1:-${CLAUDE_NTFY_TOPIC:-talkie-chloel-0d10764a8}}"
SCRIPT="$CLAUDE_DIR/hooks/ntfy_notify.py"

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR/hooks"
ln -sf "$HERE/ntfy_notify.py" "$SCRIPT"          # symlink so dotfiles edits propagate

# Merge the Notification hook into settings.json — preserve all other settings; idempotent
# (drops any prior install of this script first, so the topic stays in sync on re-run).
python3 - "$CLAUDE_DIR/settings.json" "$SCRIPT" "$TOPIC" <<'PY'
import json, os, sys
path, script, topic = sys.argv[1], sys.argv[2], sys.argv[3]
cfg = json.load(open(path)) if os.path.exists(path) else {}
cmd = f"CLAUDE_NTFY_TOPIC={topic} python3 {script}"
notif = cfg.setdefault("hooks", {}).setdefault("Notification", [])
notif[:] = [b for b in notif
            if not any("ntfy_notify.py" in h.get("command", "") for h in b.get("hooks", []))]
notif.append({"hooks": [{"type": "command", "command": cmd, "timeout": 15}]})
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"wired Notification hook -> {script}")
PY

echo "✓ installed (topic: $TOPIC)"
echo "  new Claude Code sessions push automatically; for the CURRENT session open /hooks or restart"
echo "  test: echo '{\"message\":\"test\",\"cwd\":\"'\"$PWD\"'\"}' | $SCRIPT"
