#!/bin/sh
# waterlight-membrane.sh -- Membrane (namespace/cgroup/capability) management
#
# Membranes are dynamic, adaptive boundaries that control resource flow,
# signal propagation, and capability surfaces between vertices.

set -e

VERSION="0.1.0"
RUN_DIR="/run/waterlight"
CONF_DIR="/etc/waterlight"
MEMBRANE_DIR="${RUN_DIR}/membrane"
MEMBRANE_CONF="${CONF_DIR}/membrane"
CGROUP_BASE="/sys/fs/cgroup/waterlight.slice"

# ============================================================================
# Vertex to Slice Mapping
# ============================================================================

vertex_to_slice() {
    case "$1" in
        V000) echo "neutrino" ;;
        V001) echo "antineutrino" ;;
        V010) echo "" ;;         # kernel -- no cgroup
        V011) echo "" ;;         # kernel -- no cgroup
        V100) echo "photon" ;;
        V101) echo "antiphoton" ;;
        V110) echo "electron" ;;
        V111) echo "positron" ;;
        *)    echo "" ;;
    esac
}

# Default capabilities per vertex
vertex_default_caps() {
    case "$1" in
        V100) echo "cap_net_bind_service" ;;
        V101) echo "cap_net_bind_service,cap_sys_ptrace" ;;
        V110) echo "cap_net_bind_service,cap_setuid,cap_setgid" ;;
        V111) echo "cap_net_bind_service,cap_sys_ptrace,cap_sys_admin,cap_dac_read_search" ;;
        *)    echo "" ;;
    esac
}

# ============================================================================
# Create Membrane
# ============================================================================

cmd_create() {
    local service_name=""
    local vertex="V100"
    local profile=""
    local memory_max=""
    local memory_high=""
    local cpu_weight=""
    local pids_max=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --vertex)     vertex="$2"; shift 2 ;;
            --profile)    profile="$2"; shift 2 ;;
            --memory-max) memory_max="$2"; shift 2 ;;
            --memory-high) memory_high="$2"; shift 2 ;;
            --cpu-weight) cpu_weight="$2"; shift 2 ;;
            --pids-max)   pids_max="$2"; shift 2 ;;
            -*)           echo "Unknown option: $1"; exit 1 ;;
            *)            service_name="$1"; shift ;;
        esac
    done

    if [ -z "$service_name" ]; then
        echo "Usage: waterlight-membrane create <service-name> --vertex <vertex> [options]"
        exit 1
    fi

    local slice
    slice="$(vertex_to_slice "$vertex")"
    if [ -z "$slice" ]; then
        echo "Error: Vertex ${vertex} does not support cgroup-based membranes"
        exit 1
    fi

    local slice_dir="${CGROUP_BASE}/${slice}.slice"
    local svc_dir="${slice_dir}/${service_name}"

    echo "Creating membrane for '${service_name}' in vertex ${vertex} (${slice})"

    # Create cgroup
    if [ -d "$slice_dir" ]; then
        mkdir -p "$svc_dir"
        echo "  Created cgroup: waterlight.slice/${slice}.slice/${service_name}"

        # Apply resource limits
        if [ -n "$memory_max" ]; then
            local mem_bytes
            mem_bytes="$(parse_size "$memory_max")"
            echo "$mem_bytes" > "${svc_dir}/memory.max" 2>/dev/null || true
            echo "  Memory max: ${memory_max}"
        fi

        if [ -n "$memory_high" ]; then
            local mem_bytes
            mem_bytes="$(parse_size "$memory_high")"
            echo "$mem_bytes" > "${svc_dir}/memory.high" 2>/dev/null || true
            echo "  Memory high: ${memory_high}"
        fi

        if [ -n "$cpu_weight" ]; then
            echo "$cpu_weight" > "${svc_dir}/cpu.weight" 2>/dev/null || true
            echo "  CPU weight: ${cpu_weight}"
        fi

        if [ -n "$pids_max" ]; then
            echo "$pids_max" > "${svc_dir}/pids.max" 2>/dev/null || true
            echo "  PIDs max: ${pids_max}"
        fi
    else
        echo "  Warning: Cgroup slice not found, creating record only"
    fi

    # Write membrane descriptor
    mkdir -p "$MEMBRANE_DIR"
    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    {
        echo "service=${service_name}"
        echo "vertex=${vertex}"
        echo "slice=${slice}"
        echo "created=$(date -Iseconds 2>/dev/null || date)"
        echo "memory_max=${memory_max:-default}"
        echo "memory_high=${memory_high:-default}"
        echo "cpu_weight=${cpu_weight:-default}"
        echo "pids_max=${pids_max:-default}"
        echo "caps=$(vertex_default_caps "$vertex")"
        echo "state=created"
    } > "$descriptor"

    echo "  Descriptor: ${descriptor}"
    echo "  Capabilities: $(vertex_default_caps "$vertex")"
    echo "Membrane created."
}

# ============================================================================
# Inspect Membrane
# ============================================================================

cmd_inspect() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        echo "Usage: waterlight-membrane inspect <service-name>"
        exit 1
    fi

    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    if [ ! -f "$descriptor" ]; then
        echo "Error: No membrane found for '${service_name}'"
        exit 1
    fi

    printf "\n  Membrane: %s\n" "$service_name"
    printf "  ══════════════════════════════════════════\n"

    # Read descriptor
    local vertex slice state caps
    vertex="$(grep '^vertex=' "$descriptor" | cut -d= -f2)"
    slice="$(grep '^slice=' "$descriptor" | cut -d= -f2)"
    state="$(grep '^state=' "$descriptor" | cut -d= -f2)"
    caps="$(grep '^caps=' "$descriptor" | cut -d= -f2)"

    printf "  Vertex:       %s\n" "$vertex"
    printf "  Slice:        %s\n" "$slice"
    printf "  State:        %s\n" "$state"
    printf "  Capabilities: %s\n" "$caps"

    # Live cgroup stats
    local svc_dir="${CGROUP_BASE}/${slice}.slice/${service_name}"
    if [ -d "$svc_dir" ]; then
        printf "\n  Live Resource Usage:\n"

        if [ -f "${svc_dir}/memory.current" ]; then
            local cur max high
            cur="$(cat "${svc_dir}/memory.current" 2>/dev/null || echo '0')"
            max="$(cat "${svc_dir}/memory.max" 2>/dev/null || echo 'max')"
            high="$(cat "${svc_dir}/memory.high" 2>/dev/null || echo 'max')"
            printf "    Memory: %s current / %s high / %s max\n" \
                "$(numfmt --to=iec "$cur" 2>/dev/null || echo "${cur}B")" \
                "$([ "$high" = "max" ] && echo "unlimited" || numfmt --to=iec "$high" 2>/dev/null || echo "${high}B")" \
                "$([ "$max" = "max" ] && echo "unlimited" || numfmt --to=iec "$max" 2>/dev/null || echo "${max}B")"
        fi

        if [ -f "${svc_dir}/cpu.stat" ]; then
            printf "    CPU stat:\n"
            while IFS= read -r line; do
                printf "      %s\n" "$line"
            done < "${svc_dir}/cpu.stat"
        fi

        if [ -f "${svc_dir}/pids.current" ]; then
            local pids_cur pids_max
            pids_cur="$(cat "${svc_dir}/pids.current" 2>/dev/null || echo '0')"
            pids_max="$(cat "${svc_dir}/pids.max" 2>/dev/null || echo 'max')"
            printf "    PIDs: %s / %s\n" "$pids_cur" "$pids_max"
        fi
    else
        printf "\n  Cgroup not active (service not running)\n"
    fi

    # PID info
    local pidfile="${MEMBRANE_DIR}/${service_name}.pid"
    if [ -f "$pidfile" ]; then
        local pid
        pid="$(cat "$pidfile" 2>/dev/null)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            printf "\n  Process: PID %s (running)\n" "$pid"
            # Show namespace IDs if procfs available
            if [ -d "/proc/${pid}/ns" ]; then
                printf "  Namespaces:\n"
                for ns in /proc/${pid}/ns/*; do
                    local ns_name ns_id
                    ns_name="$(basename "$ns")"
                    ns_id="$(readlink "$ns" 2>/dev/null || echo '?')"
                    printf "    %-10s %s\n" "$ns_name" "$ns_id"
                done
            fi
        else
            printf "\n  Process: PID %s (dead)\n" "$pid"
        fi
    else
        printf "\n  Process: not tracked\n"
    fi

    printf "\n"
}

# ============================================================================
# List Membranes
# ============================================================================

cmd_list() {
    printf "\n  Active Membranes\n"
    printf "  ══════════════════════════════════════════\n\n"

    printf "  %-20s %-6s %-12s %-10s %s\n" "SERVICE" "VERTEX" "SLICE" "STATE" "CAPS"
    printf "  %-20s %-6s %-12s %-10s %s\n" "--------------------" "------" "------------" "----------" "----"

    local found=0
    for descriptor in "${MEMBRANE_DIR}"/*.membrane; do
        [ -f "$descriptor" ] || continue
        found=1

        local service vertex slice state caps
        service="$(grep '^service=' "$descriptor" | cut -d= -f2)"
        vertex="$(grep '^vertex=' "$descriptor" | cut -d= -f2)"
        slice="$(grep '^slice=' "$descriptor" | cut -d= -f2)"
        state="$(grep '^state=' "$descriptor" | cut -d= -f2)"
        caps="$(grep '^caps=' "$descriptor" | cut -d= -f2)"

        printf "  %-20s %-6s %-12s %-10s %s\n" "$service" "$vertex" "$slice" "$state" "$caps"
    done

    if [ "$found" -eq 0 ]; then
        printf "  (no active membranes)\n"
    fi

    printf "\n"
}

# ============================================================================
# Stretch Membrane
# ============================================================================

cmd_stretch() {
    local service_name=""
    local memory=""
    local cpu=""
    local duration=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --memory)   memory="$2"; shift 2 ;;
            --cpu)      cpu="$2"; shift 2 ;;
            --duration) duration="$2"; shift 2 ;;
            -*)         echo "Unknown option: $1"; exit 1 ;;
            *)          service_name="$1"; shift ;;
        esac
    done

    if [ -z "$service_name" ]; then
        echo "Usage: waterlight-membrane stretch <service-name> [--memory <size>] [--cpu <weight>] [--duration <time>]"
        exit 1
    fi

    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    if [ ! -f "$descriptor" ]; then
        echo "Error: No membrane found for '${service_name}'"
        exit 1
    fi

    local slice
    slice="$(grep '^slice=' "$descriptor" | cut -d= -f2)"
    local svc_dir="${CGROUP_BASE}/${slice}.slice/${service_name}"

    echo "Stretching membrane for '${service_name}'"

    if [ -n "$memory" ] && [ -d "$svc_dir" ]; then
        # Save current for contraction
        local current_max
        current_max="$(cat "${svc_dir}/memory.max" 2>/dev/null || echo 'max')"
        echo "stretch_memory_prev=${current_max}" >> "$descriptor"

        local mem_bytes
        mem_bytes="$(parse_size "$memory")"
        echo "$mem_bytes" > "${svc_dir}/memory.max" 2>/dev/null || true
        echo "  Memory max stretched to: ${memory}"
    fi

    if [ -n "$cpu" ] && [ -d "$svc_dir" ]; then
        local current_weight
        current_weight="$(cat "${svc_dir}/cpu.weight" 2>/dev/null || echo '100')"
        echo "stretch_cpu_prev=${current_weight}" >> "$descriptor"

        echo "$cpu" > "${svc_dir}/cpu.weight" 2>/dev/null || true
        echo "  CPU weight stretched to: ${cpu}"
    fi

    # Update state
    sed -i 's/^state=.*/state=stretched/' "$descriptor" 2>/dev/null || true

    if [ -n "$duration" ]; then
        echo "  Duration: ${duration} (auto-contract after)"
        echo "  NOTE: Automatic contraction not yet implemented in v0.1"
        echo "        Run 'waterlight-membrane contract ${service_name}' manually"
    fi

    echo "Membrane stretched."
}

# ============================================================================
# Contract Membrane
# ============================================================================

cmd_contract() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        echo "Usage: waterlight-membrane contract <service-name>"
        exit 1
    fi

    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    if [ ! -f "$descriptor" ]; then
        echo "Error: No membrane found for '${service_name}'"
        exit 1
    fi

    local slice
    slice="$(grep '^slice=' "$descriptor" | cut -d= -f2)"
    local svc_dir="${CGROUP_BASE}/${slice}.slice/${service_name}"

    echo "Contracting membrane for '${service_name}'"

    # Restore previous values if they exist
    local prev_mem
    prev_mem="$(grep '^stretch_memory_prev=' "$descriptor" 2>/dev/null | tail -1 | cut -d= -f2)"
    if [ -n "$prev_mem" ] && [ -d "$svc_dir" ]; then
        echo "$prev_mem" > "${svc_dir}/memory.max" 2>/dev/null || true
        echo "  Memory max restored to: ${prev_mem}"
    fi

    local prev_cpu
    prev_cpu="$(grep '^stretch_cpu_prev=' "$descriptor" 2>/dev/null | tail -1 | cut -d= -f2)"
    if [ -n "$prev_cpu" ] && [ -d "$svc_dir" ]; then
        echo "$prev_cpu" > "${svc_dir}/cpu.weight" 2>/dev/null || true
        echo "  CPU weight restored to: ${prev_cpu}"
    fi

    # Clean up stretch records
    sed -i '/^stretch_/d' "$descriptor" 2>/dev/null || true
    sed -i 's/^state=.*/state=created/' "$descriptor" 2>/dev/null || true

    echo "Membrane contracted."
}

# ============================================================================
# Destroy Membrane
# ============================================================================

cmd_destroy() {
    local service_name="$1"
    if [ -z "$service_name" ]; then
        echo "Usage: waterlight-membrane destroy <service-name>"
        exit 1
    fi

    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    if [ ! -f "$descriptor" ]; then
        echo "Error: No membrane found for '${service_name}'"
        exit 1
    fi

    local slice
    slice="$(grep '^slice=' "$descriptor" | cut -d= -f2)"
    local svc_dir="${CGROUP_BASE}/${slice}.slice/${service_name}"

    echo "Destroying membrane for '${service_name}'"

    # Remove cgroup (must be empty)
    if [ -d "$svc_dir" ]; then
        rmdir "$svc_dir" 2>/dev/null && echo "  Removed cgroup" || echo "  Warning: cgroup not empty"
    fi

    # Remove descriptor and pidfile
    rm -f "$descriptor" "${MEMBRANE_DIR}/${service_name}.pid"
    echo "Membrane destroyed."
}

# ============================================================================
# Run a Command Inside a Membrane
# ============================================================================

cmd_run() {
    local service_name=""
    local vertex="V100"
    local cmd_args=""

    # Parse up to --
    while [ $# -gt 0 ]; do
        case "$1" in
            --vertex) vertex="$2"; shift 2 ;;
            --)       shift; break ;;
            -*)       echo "Unknown option: $1"; exit 1 ;;
            *)
                if [ -z "$service_name" ]; then
                    service_name="$1"; shift
                else
                    break
                fi
                ;;
        esac
    done

    if [ -z "$service_name" ] || [ $# -eq 0 ]; then
        echo "Usage: waterlight-membrane run <name> --vertex <vertex> -- <command> [args...]"
        exit 1
    fi

    # Create membrane if it doesn't exist
    local descriptor="${MEMBRANE_DIR}/${service_name}.membrane"
    if [ ! -f "$descriptor" ]; then
        cmd_create "$service_name" --vertex "$vertex"
    fi

    local slice
    slice="$(vertex_to_slice "$vertex")"
    local svc_dir="${CGROUP_BASE}/${slice}.slice/${service_name}"
    local caps
    caps="$(vertex_default_caps "$vertex")"

    echo "Running in membrane '${service_name}' (vertex ${vertex}):"
    echo "  Command: $*"
    echo "  Capabilities: ${caps}"

    # If unshare is available, use it for namespace isolation
    if command -v unshare >/dev/null 2>&1; then
        # Build unshare flags based on vertex
        local ns_flags="--pid --fork --mount-proc"

        case "$vertex" in
            V100|V101)
                # Full isolation for lightweight services
                ns_flags="--pid --fork --mount-proc --net --uts --ipc"
                ;;
            V110)
                # Per-service isolation for heavyweight
                ns_flags="--pid --fork --mount-proc --uts"
                ;;
            V111)
                # Minimal isolation for debug (needs to see other processes)
                ns_flags="--fork"
                ;;
        esac

        echo "  Namespaces: ${ns_flags}"

        # Move to cgroup, then exec with namespace isolation
        if [ -d "$svc_dir" ] && [ -f "${svc_dir}/cgroup.procs" ]; then
            echo $$ > "${svc_dir}/cgroup.procs" 2>/dev/null || true
        fi

        # shellcheck disable=SC2086
        exec unshare $ns_flags -- "$@"
    else
        echo "  Warning: unshare not found, running without namespace isolation"
        exec "$@"
    fi
}

# ============================================================================
# Utilities
# ============================================================================

parse_size() {
    local input="$1"
    local num unit
    num="$(echo "$input" | sed 's/[^0-9]//g')"
    unit="$(echo "$input" | sed 's/[0-9]//g' | tr '[:lower:]' '[:upper:]')"

    case "$unit" in
        K|KB)  echo $((num * 1024)) ;;
        M|MB)  echo $((num * 1024 * 1024)) ;;
        G|GB)  echo $((num * 1024 * 1024 * 1024)) ;;
        T|TB)  echo $((num * 1024 * 1024 * 1024 * 1024)) ;;
        *)     echo "$num" ;;
    esac
}

# ============================================================================
# Main
# ============================================================================

usage() {
    cat <<EOF
waterlight-membrane v${VERSION} -- Membrane management

Usage: waterlight-membrane <command> [args]

Commands:
  create <name> --vertex <V> [opts]    Create a membrane for a service
  inspect <name>                       Show membrane details and live stats
  list                                 List all active membranes
  stretch <name> [--memory M] [--cpu C] [--duration T]
                                       Temporarily expand membrane limits
  contract <name>                      Restore membrane to normal limits
  destroy <name>                       Remove a membrane
  run <name> --vertex <V> -- <cmd>     Run a command inside a membrane
  help                                 Show this help

Create Options:
  --vertex <V>       Target vertex (default: V100)
  --memory-max <M>   Hard memory limit (e.g., 128M, 1G)
  --memory-high <M>  Soft memory limit
  --cpu-weight <W>   CPU weight (1-10000, default: 100)
  --pids-max <N>     Maximum process count

EOF
}

case "${1:-help}" in
    create)   shift; cmd_create "$@" ;;
    inspect)  cmd_inspect "$2" ;;
    list)     cmd_list ;;
    stretch)  shift; cmd_stretch "$@" ;;
    contract) cmd_contract "$2" ;;
    destroy)  cmd_destroy "$2" ;;
    run)      shift; cmd_run "$@" ;;
    help|-h|--help) usage ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
