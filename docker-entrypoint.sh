#!/bin/bash
set -e

echo "=================================================="
echo " Starting Fincept Terminal Web Edition (Coolify)  "
echo "=================================================="

# Export display and sandbox flags
export DISPLAY=:1
export QT_QPA_PLATFORM=xcb
export QTWEBENGINE_DISABLE_SANDBOX=1

# Clean up stale locks from previous container runs
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# 1. Start Xvfb (Virtual Framebuffer)
RES="${RESOLUTION:-1920x1080x24}"
echo "[1/5] Starting Xvfb virtual display on :1 (${RES})..."
Xvfb :1 -screen 0 "${RES}" -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 2

# 2. Start Openbox (Lightweight Window Manager)
echo "[2/5] Starting Openbox window manager..."
openbox &
sleep 1

# 3. Start x11vnc (VNC Server)
echo "[3/5] Starting x11vnc server on port 5900..."
if [ -n "$VNC_PASSWORD" ]; then
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd
    x11vnc -display :1 -rfbport 5900 -rfbauth /root/.vnc/passwd -shared -forever -bg -nopw_warning
else
    x11vnc -display :1 -rfbport 5900 -nopw -shared -forever -bg -nopw_warning
fi

# 4. Start Websockify on both port 80 AND port 8080 (ensures Coolify / Traefik always finds it)
echo "[4/5] Starting noVNC web interface on ports 80 and 8080..."
websockify --web=/usr/share/novnc 80 localhost:5900 &
websockify --web=/usr/share/novnc 8080 localhost:5900 &
sleep 1

# 5. Launch Fincept Terminal
echo "[5/5] Launching Fincept Terminal..."
cd /opt/fincept/squashfs-root

launch_fincept() {
    if [ -f "./AppRun" ]; then
        ./AppRun "$@" &
        APP_PID=$!
    elif [ -f "./usr/bin/FinceptTerminal" ]; then
        ./usr/bin/FinceptTerminal "$@" &
        APP_PID=$!
    else
        echo "ERROR: FinceptTerminal binary not found in /opt/fincept/squashfs-root"
        # Keep openbox and xterm alive so user can debug via browser
        xterm &
        APP_PID=$!
    fi
}

launch_fincept "$@"

echo "=================================================="
echo " Fincept Terminal is ready! Access via HTTP       "
echo " Ports active: 80 and 8080                        "
echo "=================================================="

# Keep container alive and supervise FinceptTerminal
while true; do
    if ! kill -0 $APP_PID 2>/dev/null; then
        echo "[Supervisor] Fincept Terminal exited. Restarting in 3 seconds..."
        sleep 3
        launch_fincept "$@"
    fi
    sleep 5
done
