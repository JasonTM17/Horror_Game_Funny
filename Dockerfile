# syntax=docker/dockerfile:1.7
# ROOM 407: multi-stage CI/test image with Godot 4.7.1 standard (not .NET).
# Image: nguyenson1710/horror-game-suite
# Player-facing builds use the Windows export path; this image is suite-only.

ARG GODOT_VERSION=4.7.1
ARG GODOT_ZIP=Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
ARG GODOT_BIN=Godot_v${GODOT_VERSION}-stable_linux.x86_64
ARG GODOT_URL=https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${GODOT_ZIP}
# Official GitHub release asset Godot_v4.7.1-stable_linux.x86_64.zip (76056717 bytes).
ARG GODOT_SHA256=c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba

FROM debian:bookworm-slim AS builder

ARG GODOT_VERSION
ARG GODOT_ZIP
ARG GODOT_BIN
ARG GODOT_URL
ARG GODOT_SHA256

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl unzip \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /opt/godot
RUN curl -fsSL -o /tmp/godot.zip "${GODOT_URL}" \
	&& echo "${GODOT_SHA256}  /tmp/godot.zip" | sha256sum -c - \
	&& unzip -q /tmp/godot.zip -d /opt/godot \
	&& mv "/opt/godot/${GODOT_BIN}" /opt/godot/godot \
	&& chmod +x /opt/godot/godot \
	&& rm -f /tmp/godot.zip \
	&& /opt/godot/godot --version

FROM debian:bookworm-slim AS runtime

ARG GODOT_VERSION=4.7.1
ARG GODOT_SHA256=c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba

LABEL org.opencontainers.image.title="horror-game-suite" \
	org.opencontainers.image.description="Headless Godot 4.7.1 suite image for ROOM 407: THE LAST SHIFT" \
	org.opencontainers.image.source="https://github.com/JasonTM17/Horror_Game_Funny" \
	org.opencontainers.image.licenses="MIT" \
	org.opencontainers.image.version="${GODOT_VERSION}" \
	org.opencontainers.image.vendor="JasonTM17" \
	org.opencontainers.image.base.name="debian:bookworm-slim" \
	org.opencontainers.image.ref.name="nguyenson1710/horror-game-suite"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		libfontconfig1 \
		libgl1 \
		libx11-6 \
		libxcursor1 \
		libxext6 \
		libxinerama1 \
		libxrandr2 \
		libxi6 \
		libxrender1 \
	&& rm -rf /var/lib/apt/lists/* \
	&& groupadd --gid 65532 nonroot \
	&& useradd --uid 65532 --gid 65532 --create-home --home-dir /home/nonroot --shell /usr/sbin/nologin nonroot

COPY --from=builder /opt/godot/godot /usr/local/bin/godot

WORKDIR /app
COPY --chown=65532:65532 . /app

RUN chmod +x /app/tests/run-headless-tests.sh /app/tests/verify-docker-packaging.sh \
	&& mkdir -p /app/.artifacts /app/.tmp \
	&& chown -R 65532:65532 /app

USER 65532:65532
ENV HOME=/home/nonroot \
	XDG_DATA_HOME=/home/nonroot/.local/share \
	XDG_CONFIG_HOME=/home/nonroot/.config \
	XDG_CACHE_HOME=/home/nonroot/.cache \
	TEMP=/app/.tmp \
	TMP=/app/.tmp \
	GODOT=/usr/local/bin/godot

# Container-ready signal: Godot binary responds with the pinned major.minor.
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
	CMD godot --version | grep -q "4.7" || exit 1

ENTRYPOINT ["/app/tests/run-headless-tests.sh"]
CMD []
