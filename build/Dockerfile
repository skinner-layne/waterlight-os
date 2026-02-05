# Waterlight OS v0.1 -- Genesis
#
# Based on Alpine Linux: the hydrogen of Linux distributions.
# musl libc, BusyBox, apk -- the smallest functional base from which
# all heavier elements can be synthesized.
#
# Build: docker build -t waterlight-os:v0.1 .
# Run:   docker run -it --privileged waterlight-os:v0.1

# ============================================================================
# Stage 1: Alpha Frame (build environment)
# ============================================================================
FROM alpine:3.21 AS alpha-frame

# Install build dependencies
RUN apk add --no-cache \
    bash \
    coreutils \
    util-linux \
    iproute2 \
    iptables \
    nftables \
    btrfs-progs \
    e2fsprogs \
    shadow \
    procps \
    findutils \
    grep \
    sed \
    gawk

# ============================================================================
# Stage 2: Waterlight OS image
# ============================================================================
FROM alpine:3.21

LABEL maintainer="Waterlight OS Project"
LABEL version="0.1.0"
LABEL description="Waterlight OS: Z2-cubed theory operating system"
LABEL org.waterlight.codename="Genesis"

# ── Hydrogen Phase: Essential packages ──────────────────────────────────────

# Core system (pre-fusion primitives)
RUN apk add --no-cache \
    busybox \
    musl \
    musl-utils \
    bash \
    coreutils \
    util-linux \
    procps \
    findutils \
    grep \
    sed

# Membrane infrastructure (namespace/cgroup tools)
RUN apk add --no-cache \
    iproute2 \
    iptables \
    nftables \
    shadow \
    libcap \
    libcap-utils

# Filesystem (BTRFS for copy-on-write chirality)
RUN apk add --no-cache \
    btrfs-progs \
    e2fsprogs

# ── Helium Phase: Vertex-classified packages ────────────────────────────────

# V000/V001 - Kernel space tools
# (In a real system these would be kernel modules; in container we use userspace equivalents)
RUN apk add --no-cache \
    perf \
    strace \
    || true  # Some may not be available in all Alpine versions

# V100 - Photon: lightweight production daemons
RUN apk add --no-cache \
    dcron \
    chrony \
    busybox-suid

# V110 - Electron: heavyweight production services
# (Installed on demand, not in base image)

# V101 - Antiphoton: lightweight dev tools (only in antimatter mode)
# V111 - Positron: heavyweight dev tools (only in antimatter mode)
# These are available via apk but not pre-installed in matter mode

# ── Install Waterlight OS components ────────────────────────────────────────

# Create directory structure
RUN mkdir -p \
    /etc/waterlight/vertices \
    /etc/waterlight/membrane \
    /etc/waterlight/chirality \
    /etc/waterlight/fusion \
    /etc/waterlight/services \
    /run/waterlight/membrane \
    /var/waterlight/log \
    /var/waterlight/state \
    /usr/lib/waterlight/alpha-frame \
    /usr/lib/waterlight/vertex \
    /usr/lib/waterlight/membrane \
    /usr/lib/waterlight/chirality

# Copy Waterlight components
COPY ../src/alpha-frame/waterlight-init.sh /usr/lib/waterlight/alpha-frame/waterlight-init.sh
COPY ../src/vertex/waterlight-vertex.sh /usr/lib/waterlight/vertex/waterlight-vertex.sh
COPY ../src/membrane/waterlight-membrane.sh /usr/lib/waterlight/membrane/waterlight-membrane.sh
COPY ../src/chirality/waterlight-chirality.sh /usr/lib/waterlight/chirality/waterlight-chirality.sh

# Make executable
RUN chmod +x /usr/lib/waterlight/alpha-frame/waterlight-init.sh \
    && chmod +x /usr/lib/waterlight/vertex/waterlight-vertex.sh \
    && chmod +x /usr/lib/waterlight/membrane/waterlight-membrane.sh \
    && chmod +x /usr/lib/waterlight/chirality/waterlight-chirality.sh

# Create symlinks in /usr/bin
RUN ln -sf /usr/lib/waterlight/vertex/waterlight-vertex.sh /usr/bin/waterlight-vertex \
    && ln -sf /usr/lib/waterlight/membrane/waterlight-membrane.sh /usr/bin/waterlight-membrane \
    && ln -sf /usr/lib/waterlight/chirality/waterlight-chirality.sh /usr/bin/waterlight-chirality

# Copy configuration
COPY ../config/waterlight/ /etc/waterlight/

# ── Runtime Configuration ───────────────────────────────────────────────────

# Default chirality: matter (production)
RUN echo "0" > /run/waterlight/chirality

# Default vertex states
RUN printf "V000=active\nV001=inactive\nV010=active\nV011=inactive\nV100=active\nV101=inactive\nV110=active\nV111=inactive\n" \
    > /run/waterlight/vertex-state

# ── Entrypoint ──────────────────────────────────────────────────────────────

# In container mode, we don't run as PID 1 init.
# Instead, start a shell with the Waterlight environment.
ENV WATERLIGHT_VERSION="0.1.0"
ENV WATERLIGHT_CODENAME="Genesis"
ENV WATERLIGHT_SIGMA="0"

ENTRYPOINT ["/bin/bash"]
CMD ["--login"]
