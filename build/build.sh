#!/bin/bash
# build.sh -- Waterlight OS build orchestrator
#
# Builds the Waterlight OS container image and optionally generates
# an installable root filesystem.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

VERSION="0.1.0"
CODENAME="Genesis"
IMAGE_NAME="waterlight-os"
IMAGE_TAG="v${VERSION}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { printf "${BLUE}[waterlight]${NC} %s\n" "$*"; }
ok()  { printf "${GREEN}[waterlight]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[waterlight]${NC} %s\n" "$*"; }
err() { printf "${RED}[waterlight]${NC} %s\n" "$*" >&2; }

# ============================================================================
# Build Modes
# ============================================================================

build_container() {
    log "Building Waterlight OS container image..."
    log "  Version: ${VERSION} (${CODENAME})"
    log "  Image:   ${IMAGE_NAME}:${IMAGE_TAG}"

    # Docker requires build context, so we build from project root
    # with Dockerfile path specified
    cd "$PROJECT_DIR"

    if command -v docker >/dev/null 2>&1; then
        docker build \
            -f build/Dockerfile \
            -t "${IMAGE_NAME}:${IMAGE_TAG}" \
            -t "${IMAGE_NAME}:latest" \
            --build-arg WATERLIGHT_VERSION="${VERSION}" \
            --build-arg WATERLIGHT_CODENAME="${CODENAME}" \
            .
        ok "Container image built: ${IMAGE_NAME}:${IMAGE_TAG}"
    elif command -v podman >/dev/null 2>&1; then
        podman build \
            -f build/Dockerfile \
            -t "${IMAGE_NAME}:${IMAGE_TAG}" \
            -t "${IMAGE_NAME}:latest" \
            .
        ok "Container image built (podman): ${IMAGE_NAME}:${IMAGE_TAG}"
    else
        err "Neither docker nor podman found. Cannot build container image."
        exit 1
    fi
}

build_rootfs() {
    log "Building Waterlight OS root filesystem..."

    local rootfs_dir="${PROJECT_DIR}/build/output/rootfs"
    mkdir -p "$rootfs_dir"

    # Create directory structure
    log "Creating filesystem layout..."
    mkdir -p "${rootfs_dir}"/{bin,sbin,etc,proc,sys,dev,run,tmp,var,usr/{bin,lib,share},home,root}
    mkdir -p "${rootfs_dir}/etc/waterlight"/{vertices,membrane,chirality,fusion,services}
    mkdir -p "${rootfs_dir}/run/waterlight/membrane"
    mkdir -p "${rootfs_dir}/var/waterlight"/{log,state}
    mkdir -p "${rootfs_dir}/usr/lib/waterlight"/{alpha-frame,vertex,membrane,chirality}

    # Copy Waterlight components
    log "Installing Waterlight components..."
    cp "${PROJECT_DIR}/src/alpha-frame/waterlight-init.sh" "${rootfs_dir}/usr/lib/waterlight/alpha-frame/"
    cp "${PROJECT_DIR}/src/vertex/waterlight-vertex.sh" "${rootfs_dir}/usr/lib/waterlight/vertex/"
    cp "${PROJECT_DIR}/src/membrane/waterlight-membrane.sh" "${rootfs_dir}/usr/lib/waterlight/membrane/"
    cp "${PROJECT_DIR}/src/chirality/waterlight-chirality.sh" "${rootfs_dir}/usr/lib/waterlight/chirality/"

    chmod +x "${rootfs_dir}/usr/lib/waterlight/"*/*.sh

    # Symlinks
    ln -sf /usr/lib/waterlight/alpha-frame/waterlight-init.sh "${rootfs_dir}/sbin/init"
    ln -sf /usr/lib/waterlight/vertex/waterlight-vertex.sh "${rootfs_dir}/usr/bin/waterlight-vertex"
    ln -sf /usr/lib/waterlight/membrane/waterlight-membrane.sh "${rootfs_dir}/usr/bin/waterlight-membrane"
    ln -sf /usr/lib/waterlight/chirality/waterlight-chirality.sh "${rootfs_dir}/usr/bin/waterlight-chirality"

    # Copy configuration
    cp -r "${PROJECT_DIR}/config/waterlight/"* "${rootfs_dir}/etc/waterlight/" 2>/dev/null || true

    ok "Root filesystem created: ${rootfs_dir}"
    log "Size: $(du -sh "$rootfs_dir" | cut -f1)"
}

build_initramfs() {
    log "Building initramfs..."

    local initramfs_dir="${PROJECT_DIR}/build/output/initramfs"
    local initramfs_img="${PROJECT_DIR}/build/output/waterlight-initramfs.cpio.gz"

    mkdir -p "$initramfs_dir"
    mkdir -p "${initramfs_dir}"/{bin,etc/waterlight,lib/modules,dev,proc,sys,run,mnt/root}

    # Copy init
    cp "${PROJECT_DIR}/src/alpha-frame/waterlight-init.sh" "${initramfs_dir}/init"
    chmod +x "${initramfs_dir}/init"

    # Copy minimal config
    if [ -f "${PROJECT_DIR}/config/waterlight/alpha.conf" ]; then
        cp "${PROJECT_DIR}/config/waterlight/alpha.conf" "${initramfs_dir}/etc/waterlight/"
    fi

    # Note: in a real build, we'd include busybox here
    log "  NOTE: initramfs requires busybox binary (not included in scaffold)"

    # Create cpio archive
    cd "$initramfs_dir"
    find . | cpio -o -H newc 2>/dev/null | gzip > "$initramfs_img" 2>/dev/null || {
        warn "cpio/gzip not available, skipping initramfs image creation"
        return 0
    }

    ok "initramfs created: ${initramfs_img}"
    log "Size: $(du -sh "$initramfs_img" 2>/dev/null | cut -f1 || echo 'unknown')"
}

# ============================================================================
# Validation
# ============================================================================

validate() {
    log "Validating Waterlight OS components..."
    local errors=0

    # Check all source files exist
    local sources="src/alpha-frame/waterlight-init.sh src/vertex/waterlight-vertex.sh src/membrane/waterlight-membrane.sh src/chirality/waterlight-chirality.sh"
    for src in $sources; do
        if [ -f "${PROJECT_DIR}/${src}" ]; then
            ok "  Found: ${src}"
        else
            err "  Missing: ${src}"
            errors=$((errors + 1))
        fi
    done

    # Check scripts are valid shell
    for src in $sources; do
        local filepath="${PROJECT_DIR}/${src}"
        if [ -f "$filepath" ]; then
            if bash -n "$filepath" 2>/dev/null; then
                ok "  Syntax OK: ${src}"
            else
                err "  Syntax error: ${src}"
                errors=$((errors + 1))
            fi
        fi
    done

    # Check configs exist
    local configs="config/waterlight/system.conf config/waterlight/alpha.conf"
    for conf in $configs; do
        if [ -f "${PROJECT_DIR}/${conf}" ]; then
            ok "  Found: ${conf}"
        else
            warn "  Missing: ${conf}"
        fi
    done

    if [ "$errors" -eq 0 ]; then
        ok "Validation passed."
    else
        err "Validation failed with ${errors} error(s)."
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

usage() {
    cat <<EOF
Waterlight OS Build System v${VERSION}

Usage: build.sh <command>

Commands:
  container    Build Docker/Podman container image
  rootfs       Build root filesystem directory
  initramfs    Build initramfs image
  validate     Validate all components
  all          Build everything
  clean        Remove build artifacts
  help         Show this help

EOF
}

case "${1:-help}" in
    container)  build_container ;;
    rootfs)     build_rootfs ;;
    initramfs)  build_initramfs ;;
    validate)   validate ;;
    all)
        validate
        build_rootfs
        build_initramfs
        build_container
        ;;
    clean)
        log "Cleaning build artifacts..."
        rm -rf "${PROJECT_DIR}/build/output"
        ok "Clean."
        ;;
    help|-h|--help) usage ;;
    *)
        err "Unknown command: $1"
        usage
        exit 1
        ;;
esac
