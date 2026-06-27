# claude — push notifications

Phone push (via [ntfy.sh](https://ntfy.sh)) whenever a Claude Code session needs your input — a
permission prompt or an idle wait. Title is `<project> · Claude needs you`; body is Claude Code's
message. Repo-agnostic and stdlib-only.

## Install (per node/cluster)

```bash
./install.sh [ntfy-topic]      # default topic: talkie-chloel-0d10764a8
```

This symlinks `~/.claude/hooks/ntfy_notify.py` → this dir and adds a global `Notification` hook to
`~/.claude/settings.json` (merging, never clobbering). Re-run anytime to update the topic.

`~/.claude` is **per-node-local** on the fellows cluster, so run `install.sh` once on each node you
start `claude` from. Then subscribe to the topic in the ntfy phone/web app.

## Notes
- Needs `python3` + outbound HTTPS to `ntfy.sh`. Behind a strict firewall, point the script at a
  reachable channel (e.g. a Slack webhook) — one line in `ntfy_notify.py`.
- Distinct from the talkie **dashboard** experiment pings (review/failed); they can share a topic
  or use different ones (`CLAUDE_NTFY_TOPIC` here vs `NTFY_TOPIC` in the collector).
