#!/bin/sh
# waterlight-init.sh -- PID 1 for Waterlight OS
# Alpha Frame: The pre-cubic foundation from which all vertices instantiate.
#
# This is the hydrogen of the system. It must be the simplest possible
# init that can bring the Z2-cubed cube into existence.
#
# IMPORTANT: This script runs as PID 1. If it exits, the kernel panics.
# All errors must be handled. All child processes must be reaped.

set -e

# ============================================================================
# Constants
# ============================================================================

WATERLIGHT_VERSION="0.1.0"
WATERLIGHT_CODENAME="Genesis"

CONF_DIR="/etc/waterlight"
RUN_DIR="/run/waterlight"
LOG_DIR="/var/waterlight/log"
STATE_DIR="/var/waterlight/state"

ALPHA_CONF="${CONF_DIR}/alpha.conf"
SYSTEM_CONF="${CONF_DIR}/system.conf"

# Cgroup v2 base
CGROUP_BASE="/sys/fs/cgroup"
WL_SLICE="${CGROUP_BASE}/waterlight.slice"

# Boot phases (nucleosynthesis)
PHASE_HYDROGEN=1
PHASE_HELIUM=2
PHASE_CARBON=3
PHASE_OXYGEN=4
PHASE_IRON=5

# Current sigma (polarity): 0=matter/production, 1=antimatter/development
SIGMA=0

# ============================================================================
# Logging
# ============================================================================

BOOT_START=""

log() {
    local level="$1"
    shift
    local timestamp
    timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || echo 'unknown')"
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$*"
    if [ -d "$LOG_DIR" ]; then
        printf "[%s] [%s] %s\n" "$timestamp" "$level" "$*" >> "${LOG_DIR}/boot.log" 2>/dev/null || true
    fi
}

log_phase() {
    local phase="$1"
    local name="$2"
    log "PHASE" "═══ Phase ${phase}: ${name} ═══"
}

die() {
    log "FATAL" "$*"
    log "FATAL" "Dropping to emergency shell. Type 'exit' to retry boot."
    exec /bin/sh
}

# ============================================================================
# Configuration Parser
# ============================================================================

# Simple INI parser: reads key=value pairs from a section
conf_get() {
    local file="$1"
    local section="$2"
    local key="$3"
    local default="$4"

    if [ ! -f "$file" ]; then
        echo "$default"
        return
    fi

    local in_section=0
    local value=""
    while IFS= read -r line; do
        # Strip comments and whitespace
        line="${line%%#*}"
        case "$line" in
            "["*"]"*)
                if [ "$in_section" -eq 1 ]; then
                    break
                fi
                local sec
                sec="$(echo "$line" | tr -d '[]' | tr -d ' ')"
                if [ "$sec" = "$section" ]; then
                    in_section=1
                fi
                ;;
            *"="*)
                if [ "$in_section" -eq 1 ]; then
                    local k v
                    k="$(echo "${line%%=*}" | tr -d ' ')"
                    v="$(echo "${line#*=}" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
                    if [ "$k" = "$key" ]; then
                        value="$v"
                    fi
                fi
                ;;
        esac
    done < "$file"

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# ============================================================================
# Phase 1: Hydrogen
# Mount essential filesystems, load modules, mount root, pivot.
# ============================================================================

phase_hydrogen() {
    log_phase $PHASE_HYDROGEN "HYDROGEN"
    BOOT_START="$(date +%s 2>/dev/null || echo 0)"

    # Mount essential virtual filesystems
    log "INFO" "Mounting essential filesystems"

    mountpoint -q /proc 2>/dev/null || mount -t proc proc /proc
    mountpoint -q /sys 2>/dev/null || mount -t sysfs sysfs /sys
    mountpoint -q /dev 2>/dev/null || mount -t devtmpfs devtmpfs /dev

    mkdir -p /dev/pts /dev/shm /dev/mqueue
    mountpoint -q /dev/pts 2>/dev/null || mount -t devpts devpts /dev/pts
    mountpoint -q /dev/shm 2>/dev/null || mount -t tmpfs tmpfs /dev/shm

    # Runtime directory
    mkdir -p /run
    mountpoint -q /run 2>/dev/null || mount -t tmpfs tmpfs /run -o mode=0755,nosuid,nodev

    # Mount cgroup v2
    mkdir -p "${CGROUP_BASE}"
    if ! mountpoint -q "${CGROUP_BASE}" 2>/dev/null; then
        mount -t cgroup2 none "${CGROUP_BASE}" || log "WARN" "cgroup2 mount failed"
    fi

    # Load configuration
    SIGMA="$(conf_get "$ALPHA_CONF" boot sigma 0)"
    local verbose
    verbose="$(conf_get "$ALPHA_CONF" boot verbose 0)"

    log "INFO" "Boot mode: sigma=${SIGMA} ($([ "$SIGMA" = "0" ] && echo 'production' || echo 'development'))"

    # Load kernel modules
    local modules
    modules="$(conf_get "$ALPHA_CONF" hydrogen modules "")"
    if [ -n "$modules" ]; then
        log "INFO" "Loading kernel modules: ${modules}"
        for mod in $modules; do
            modprobe "$mod" 2>/dev/null && log "INFO" "  Loaded: ${mod}" || log "WARN" "  Failed: ${mod}"
        done
    fi

    # Seed entropy
    if [ -f /var/waterlight/state/random-seed ]; then
        cat /var/waterlight/state/random-seed > /dev/urandom 2>/dev/null || true
        log "INFO" "Entropy seeded from saved state"
    fi

    log "INFO" "Hydrogen phase complete"
}

# ============================================================================
# Phase 2: Helium Fusion
# Create cgroup hierarchy, establish vertex slices, initialize runtime state.
# ============================================================================

phase_helium() {
    log_phase $PHASE_HELIUM "HELIUM FUSION"

    # Create Waterlight cgroup hierarchy
    log "INFO" "Creating vertex cgroup hierarchy"
    mkdir -p "${WL_SLICE}"

    # Enable controllers on parent
    if [ -f "${CGROUP_BASE}/cgroup.subtree_control" ]; then
        echo "+memory +cpu +io +pids" > "${CGROUP_BASE}/cgroup.subtree_control" 2>/dev/null || true
    fi
    if [ -f "${WL_SLICE}/cgroup.subtree_control" ]; then
        echo "+memory +cpu +io +pids" > "${WL_SLICE}/cgroup.subtree_control" 2>/dev/null || true
    fi

    # Create vertex slices
    local vertices="neutrino antineutrino photon antiphoton electron positron"
    for v in $vertices; do
        local slice_dir="${WL_SLICE}/${v}.slice"
        mkdir -p "$slice_dir"
        log "INFO" "  Created slice: ${v}"

        # Enable controllers on vertex slice
        if [ -f "${slice_dir}/cgroup.subtree_control" ]; then
            echo "+memory +cpu +io +pids" > "${slice_dir}/cgroup.subtree_control" 2>/dev/null || true
        fi
    done

    # Apply vertex resource defaults
    apply_vertex_defaults

    # Initialize runtime state directories
    log "INFO" "Initializing runtime state"
    mkdir -p "${RUN_DIR}"
    mkdir -p "${RUN_DIR}/membrane"
    mkdir -p "${LOG_DIR}"
    mkdir -p "${STATE_DIR}"

    # Write vertex state
    printf "V000=active\nV001=%s\nV010=active\nV011=%s\nV100=pending\nV101=%s\nV110=pending\nV111=%s\n" \
        "$([ "$SIGMA" = "1" ] && echo 'pending' || echo 'inactive')" \
        "$([ "$SIGMA" = "1" ] && echo 'pending' || echo 'inactive')" \
        "$([ "$SIGMA" = "1" ] && echo 'pending' || echo 'inactive')" \
        "$([ "$SIGMA" = "1" ] && echo 'pending' || echo 'inactive')" \
        > "${RUN_DIR}/vertex-state"

    # Write chirality state
    echo "$SIGMA" > "${RUN_DIR}/chirality"

    # Set hostname
    local hostname
    hostname="$(conf_get "$ALPHA_CONF" helium hostname waterlight)"
    echo "$hostname" > /etc/hostname 2>/dev/null || true
    hostname "$hostname" 2>/dev/null || true
    log "INFO" "Hostname: ${hostname}"

    # Set timezone
    local timezone
    timezone="$(conf_get "$ALPHA_CONF" helium timezone UTC)"
    if [ -f "/usr/share/zoneinfo/${timezone}" ]; then
        ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime 2>/dev/null || true
    fi
    log "INFO" "Timezone: ${timezone}"

    log "INFO" "Helium fusion complete"
}

apply_vertex_defaults() {
    # Photon (V100): lightweight production
    local photon="${WL_SLICE}/photon.slice"
    if [ -d "$photon" ]; then
        echo "134217728" > "${photon}/memory.max" 2>/dev/null || true   # 128M hard
        echo "67108864" > "${photon}/memory.high" 2>/dev/null || true    # 64M soft
        echo "25" > "${photon}/cpu.weight" 2>/dev/null || true
        echo "256" > "${photon}/pids.max" 2>/dev/null || true
    fi

    # Antiphoton (V101): lightweight dev
    local antiphoton="${WL_SLICE}/antiphoton.slice"
    if [ -d "$antiphoton" ]; then
        echo "134217728" > "${antiphoton}/memory.max" 2>/dev/null || true
        echo "67108864" > "${antiphoton}/memory.high" 2>/dev/null || true
        echo "25" > "${antiphoton}/cpu.weight" 2>/dev/null || true
        echo "256" > "${antiphoton}/pids.max" 2>/dev/null || true
    fi

    # Electron (V110): heavyweight production
    local electron="${WL_SLICE}/electron.slice"
    if [ -d "$electron" ]; then
        echo "max" > "${electron}/memory.max" 2>/dev/null || true
        echo "1073741824" > "${electron}/memory.high" 2>/dev/null || true  # 1G soft
        echo "100" > "${electron}/cpu.weight" 2>/dev/null || true
        echo "4096" > "${electron}/pids.max" 2>/dev/null || true
    fi

    # Positron (V111): heavyweight dev
    local positron="${WL_SLICE}/positron.slice"
    if [ -d "$positron" ]; then
        echo "max" > "${positron}/memory.max" 2>/dev/null || true
        echo "2147483648" > "${positron}/memory.high" 2>/dev/null || true  # 2G soft
        echo "200" > "${positron}/cpu.weight" 2>/dev/null || true
        echo "16384" > "${positron}/pids.max" 2>/dev/null || true
    fi
}

# ============================================================================
# Phase 3: Carbon Fusion
# Start essential services (V000 kernel-adjacent, V100 lightweight production).
# ============================================================================

phase_carbon() {
    log_phase $PHASE_CARBON "CARBON FUSION"

    # Read configured carbon-phase services
    local services
    services="$(conf_get "$ALPHA_CONF" carbon services "syslogd crond")"

    log "INFO" "Starting carbon-phase services: ${services}"

    for svc in $services; do
        start_service "$svc" "photon"
    done

    # Update vertex state
    sed -i 's/^V100=pending/V100=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true

    log "INFO" "Carbon fusion complete"
}

# ============================================================================
# Phase 4: Oxygen Fusion
# Start application services (V110 heavyweight production).
# If sigma=1, also start antimatter vertices.
# ============================================================================

phase_oxygen() {
    log_phase $PHASE_OXYGEN "OXYGEN FUSION"

    # Load service definitions from fusion directory
    local fusion_dir="${CONF_DIR}/fusion"
    if [ -d "$fusion_dir" ]; then
        for fusion_file in "$fusion_dir"/*.fusion; do
            [ -f "$fusion_file" ] || continue
            local svc_name
            svc_name="$(basename "$fusion_file" .fusion)"
            local svc_vertex
            svc_vertex="$(conf_get "$fusion_file" identity vertex V110)"
            local svc_phase
            svc_phase="$(conf_get "$fusion_file" lifecycle start_phase oxygen)"

            if [ "$svc_phase" = "oxygen" ]; then
                local vertex_slice
                case "$svc_vertex" in
                    V100) vertex_slice="photon" ;;
                    V110) vertex_slice="electron" ;;
                    *) vertex_slice="electron" ;;
                esac
                start_service "$svc_name" "$vertex_slice"
            fi
        done
    fi

    # Update vertex state
    sed -i 's/^V110=pending/V110=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true

    # If antimatter mode, activate sigma=1 vertices
    if [ "$SIGMA" = "1" ]; then
        log "INFO" "Antimatter mode: activating development vertices"
        sed -i 's/^V001=pending/V001=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true
        sed -i 's/^V011=pending/V011=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true
        sed -i 's/^V101=pending/V101=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true
        sed -i 's/^V111=pending/V111=active/' "${RUN_DIR}/vertex-state" 2>/dev/null || true
    fi

    log "INFO" "Oxygen fusion complete"
}

# ============================================================================
# Phase 5: Iron Ceiling
# Boot is complete. No further automatic fusion.
# ============================================================================

phase_iron() {
    log_phase $PHASE_IRON "IRON CEILING"

    local boot_end
    boot_end="$(date +%s 2>/dev/null || echo 0)"
    local boot_duration=$((boot_end - BOOT_START))

    log "INFO" "Boot complete in ${boot_duration}s"
    log "INFO" "Waterlight OS v${WATERLIGHT_VERSION} (${WATERLIGHT_CODENAME})"
    log "INFO" "Sigma: ${SIGMA} ($([ "$SIGMA" = "0" ] && echo 'MATTER/PRODUCTION' || echo 'ANTIMATTER/DEVELOPMENT'))"
    log "INFO" "Iron ceiling reached. Manual operations only beyond this point."

    # Write boot-complete marker
    echo "${boot_end}" > "${RUN_DIR}/boot-complete"

    # Write boot summary
    {
        echo "version=${WATERLIGHT_VERSION}"
        echo "codename=${WATERLIGHT_CODENAME}"
        echo "sigma=${SIGMA}"
        echo "boot_time=${boot_duration}"
        echo "boot_complete=$(date -Iseconds 2>/dev/null || echo unknown)"
    } > "${RUN_DIR}/boot-summary"
}

# ============================================================================
# Service Management (minimal)
# ============================================================================

start_service() {
    local name="$1"
    local vertex_slice="$2"

    local svc_script="/etc/waterlight/services/${name}"
    local svc_init="/etc/init.d/${name}"

    if [ -x "$svc_script" ]; then
        log "INFO" "  Starting ${name} (waterlight service) in ${vertex_slice}"
        "$svc_script" start &
    elif [ -x "$svc_init" ]; then
        log "INFO" "  Starting ${name} (init.d) in ${vertex_slice}"
        "$svc_init" start &
    else
        log "WARN" "  Service not found: ${name}"
        return 1
    fi

    # Record service PID for supervision
    local pid=$!
    echo "${pid}" > "${RUN_DIR}/membrane/${name}.pid" 2>/dev/null || true
    return 0
}

# ============================================================================
# Signal Handlers
# ============================================================================

handle_shutdown() {
    log "INFO" "═══ Shutdown signal received ═══"
    log "INFO" "Beginning reverse nucleosynthesis..."

    # Save entropy for next boot
    if [ -c /dev/urandom ]; then
        dd if=/dev/urandom of=/var/waterlight/state/random-seed bs=512 count=1 2>/dev/null || true
    fi

    # Phase -1: Stop V110/V111 (oxygen decay)
    log "INFO" "Phase -1: Stopping heavyweight services"
    for pidfile in "${RUN_DIR}/membrane"/*.pid; do
        [ -f "$pidfile" ] || continue
        local pid
        pid="$(cat "$pidfile" 2>/dev/null)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # Wait briefly for graceful shutdown
    sleep 2

    # Force kill remaining
    for pidfile in "${RUN_DIR}/membrane"/*.pid; do
        [ -f "$pidfile" ] || continue
        local pid
        pid="$(cat "$pidfile" 2>/dev/null)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    # Phase -2: Unmount and sync
    log "INFO" "Phase -2: Syncing filesystems"
    sync

    # Phase -3: Final
    log "INFO" "Phase -3: System halt"

    # Determine shutdown mode from signal
    case "$1" in
        TERM) exec /sbin/reboot -f 2>/dev/null || exec reboot -f ;;
        USR1) exec /sbin/halt -f 2>/dev/null || exec halt -f ;;
        USR2) exec /sbin/poweroff -f 2>/dev/null || exec poweroff -f ;;
    esac
}

# ============================================================================
# Orphan Reaper
# PID 1 must reap all orphaned child processes to prevent zombies.
# ============================================================================

reap_orphans() {
    while true; do
        wait -n 2>/dev/null || true
        # Also check for supervised services that died
        for pidfile in "${RUN_DIR}/membrane"/*.pid; do
            [ -f "$pidfile" ] || continue
            local pid
            pid="$(cat "$pidfile" 2>/dev/null)"
            if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
                local svc
                svc="$(basename "$pidfile" .pid)"
                log "WARN" "Service died: ${svc} (PID ${pid})"
                rm -f "$pidfile"
                # TODO: restart logic based on fusion file config
            fi
        done
        sleep 5
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    log "INFO" "╔══════════════════════════════════════════════════════╗"
    log "INFO" "║  Waterlight OS v${WATERLIGHT_VERSION} -- ${WATERLIGHT_CODENAME}                      ║"
    log "INFO" "║  The Alpha Frame awakens.                            ║"
    log "INFO" "╚══════════════════════════════════════════════════════╝"

    # Set up signal handlers
    trap 'handle_shutdown TERM' TERM
    trap 'handle_shutdown USR1' USR1
    trap 'handle_shutdown USR2' USR2
    trap '' INT  # Ignore Ctrl+C (PID 1 should not be interruptible)

    # Execute nucleosynthesis phases
    phase_hydrogen || die "Hydrogen phase failed"
    phase_helium   || die "Helium fusion failed"
    phase_carbon   || die "Carbon fusion failed"
    phase_oxygen   || die "Oxygen fusion failed"
    phase_iron

    # Enter steady-state: reap orphans and supervise
    log "INFO" "Entering steady-state supervision"
    reap_orphans
}

# Only run main if we're being executed (not sourced)
case "$0" in
    *waterlight-init*) main "$@" ;;
esac
