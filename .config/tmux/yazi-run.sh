#!/usr/bin/env bash
set +e

"$@"
status=$?

# Close the outer display-popup cleanly before the disposable yazi server exits.
tmux detach-client >/dev/null 2>&1 || true
sleep 0.05
exit "$status"
