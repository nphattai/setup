#!/bin/sh
set -e

# engine-state.json caches the absolute configPath + engine kind from the host
# (an nvm path that does not exist in this image). iii.pid points at a host PID.
# Remove both so the CLI re-resolves the bundled (overlaid) config and a fresh
# engine on boot.
rm -f /root/.agentmemory/engine-state.json /root/.agentmemory/iii.pid 2>/dev/null || true

# /data is a bind mount of the host state store; make sure it exists.
mkdir -p /data

# The viewer/dashboard binds 127.0.0.1:3113 inside the container (not 0.0.0.0),
# so the published port can't reach it directly. Forward on a DISTINCT port
# (0.0.0.0:3114) to avoid colliding with the viewer's own 127.0.0.1:3113 bind
# (a same-port socat shadows the viewer and loops onto itself). The host maps
# 3113 -> container 3114.
socat TCP-LISTEN:3114,fork,reuseaddr TCP:127.0.0.1:3113 &

exec "$@"
