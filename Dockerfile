FROM debian:13-slim AS fetch
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp
RUN curl -fL https://github.com/stablyai/orca/releases/latest/download/orca-linux.AppImage -o orca.AppImage \
    && chmod +x orca.AppImage && ./orca.AppImage --appimage-extract >/dev/null \
    && mv squashfs-root /opt/orca \
    && find /opt/orca/locales -type f ! -name 'en-US.pak' -delete

FROM debian:13-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl xvfb libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libasound2 libpango-1.0-0 \
    libgtk-3-0 libxshmfence1 fontconfig fonts-dejavu-core git ca-certificates \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

COPY --from=fetch /opt/orca /opt/orca

RUN echo 'export PATH="$HOME/.local/bin:$PATH:/host/usr/bin"' > /etc/profile.d/local-bin.sh
ENV PATH="/home/orca/.local/bin:${PATH}:/host/usr/bin"

RUN useradd -m -s /bin/bash orca
USER orca
WORKDIR /home/orca

ENV LIBGL_ALWAYS_SOFTWARE=1 ELECTRON_DISABLE_SANDBOX=1 DBUS_SESSION_BUS_ADDRESS=disabled: ORCA_PAIRING_ADDRESS=127.0.0.1

LABEL org.opencontainers.image.source=https://github.com/altrao/orca-headless
                                                                                        
EXPOSE 6768
CMD ["sh", "-c", "exec /opt/orca/AppRun serve --port 6768 --pairing-address \"$ORCA_PAIRING_ADDRESS\" --password-store=basic"]