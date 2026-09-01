FROM --platform=linux/arm64 lscr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

ENV TITLE="Enpass"
ENV DEBIAN_FRONTEND=noninteractive

# Software-Rendering für Qt/OpenGL (stabile GUI über Box64)
ENV QT_QUICK_BACKEND=software
ENV LIBGL_ALWAYS_SOFTWARE=1

# 1. System aktualisieren, Build-Tools, xclip (Clipboard) & wmctrl (Fenster-Steuerung) installieren
RUN rm -f /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    cmake \
    build-essential \
    ca-certificates \
    gnupg \
    zstd \
    wmctrl \
    xclip \
    xsel \
    python3-xdg \
    libgl1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libxcb-xinput0 \
    libx11-xcb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libxcb-xfixes0 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    fonts-liberation \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# 2. Box64 aus den Quellen kompilieren (wird aus dem Docker-Cache geladen!)
RUN git clone --depth 1 https://github.com/ptitSeb/box64.git /tmp/box64 \
    && mkdir -p /tmp/box64/build \
    && cd /tmp/box64/build \
    && cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/box64

# 3. Enpass amd64-Paket herunterladen und entpacken
WORKDIR /tmp/enpass
RUN curl -fsSL -A "Mozilla/5.0" https://apt.enpass.io/keys/enpass-linux.key | gpg --dearmor -o /usr/share/keyrings/enpass-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/enpass-archive-keyring.gpg] https://apt.enpass.io/ stable main" > /etc/apt/sources.list.d/enpass.list \
    && apt-get update \
    && apt-get download enpass:amd64 \
    && dpkg-deb -x enpass_*.deb / \
    && rm -rf /tmp/enpass /var/lib/apt/lists/*

# 4. Start-Wrapper mit X-Display, XDG-Fix & automatischer Wiederherstellung
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
export XDG_RUNTIME_DIR=/tmp/runtime-abc\n\
mkdir -p $XDG_RUNTIME_DIR\n\
chmod 0700 $XDG_RUNTIME_DIR\n\
if pgrep -f "Enpass" > /dev/null; then\n\
    wmctrl -R Enpass || true\n\
else\n\
    exec /usr/local/bin/box64 /opt/enpass/Enpass\n\
fi' > /usr/local/bin/start-enpass.sh && \
    chmod +x /usr/local/bin/start-enpass.sh

# 5. Autostart-Verzeichnis vorbereiten
RUN mkdir -p /defaults && \
    echo '#!/bin/bash\nexec /usr/local/bin/start-enpass.sh' > /defaults/autostart && \
    chmod +x /defaults/autostart
