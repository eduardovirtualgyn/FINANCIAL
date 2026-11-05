# ─────────────────────────────────────────────────────────────────────────────
# Fincept Terminal Web Edition for Coolify / VPS
#
# Runs the full Fincept Terminal desktop application inside a Docker container
# with an in-memory X11 virtual display (Xvfb) and an HTML5 noVNC bridge.
#
# Access via web browser on port 8080 (http://<vps-ip>:8080 or Coolify domain).
# ─────────────────────────────────────────────────────────────────────────────

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DISPLAY=:1 \
    RESOLUTION=1920x1080x24 \
    VNC_PORT=5900 \
    WEB_PORT=8080

# 1. Install runtime dependencies, virtual display, window manager, and noVNC
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        locales \
        xvfb \
        openbox \
        x11vnc \
        novnc \
        websockify \
        python3 \
        python3-pip \
        python3-venv \
        # OpenGL / EGL
        libgl1-mesa-glx \
        libgl1-mesa-dri \
        libglu1-mesa \
        libegl1 \
        # Audio / Media
        libpulse0 \
        libasound2 \
        # X11 / XCB runtime libraries
        libdbus-1-3 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libfontconfig1 \
        libfreetype6 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-sync1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        # QtWebEngine / Chromium dependencies
        libnss3 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libdrm2 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libpango-1.0-0 \
        libcairo2 \
        # Utilities & FUSE
        libfuse2 \
        xterm \
        # Fonts
        fonts-dejavu-core \
        fonts-noto-color-emoji \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/fincept

# 2. Download official pre-compiled Fincept Terminal Linux AppImage release (v4.5.1)
# and extract it. This eliminates the multi-hour C++ compile that crashes VPS instances.
RUN wget -q "https://github.com/Fincept-Corporation/FinceptTerminal/releases/download/v4.5.1/FinceptTerminal-4.5.1-linux-x64-setup.run" -O /opt/fincept/fincept.run \
    && chmod +x /opt/fincept/fincept.run \
    && /opt/fincept/fincept.run --appimage-extract \
    && rm -f /opt/fincept/fincept.run

# 3. Synchronize local scripts & resources from repository into the application tree
COPY fincept-qt/scripts /opt/fincept/squashfs-root/usr/bin/scripts
COPY fincept-qt/resources /opt/fincept/squashfs-root/usr/bin/resources

# 4. Configure entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 5. Make noVNC auto-connect by default when loading root URL
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale"></head><body>Redirecting to Fincept Terminal...</body></html>' > /usr/share/novnc/index.html

EXPOSE 80 8080 5900

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
