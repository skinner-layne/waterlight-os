#!/bin/sh
# waterlight-vertex.sh -- Vertex state management for Waterlight OS
#
# Query, inspect, and manage the eight vertices of the Z2-cubed cube.
# Each vertex represents a subsystem class defined by three binary axes:
#   epsilon (visibility): 0=kernel, 1=user
#   mu (weight): 0=lightweight, 1=heavyweight
#   sigma (polarity): 0=production, 1=development

set -e

VERSION="0.1.0"
RUN_DIR="/run/waterlight"
CONF_DIR="/etc/waterlight"
CGROUP_BASE="/sys/fs/cgroup/waterlight.slice"
STATE_FILE="${RUN_DIR}/vertex-state"
CHIRALITY_FILE="${RUN_DIR}/chirality"

# ============================================================================
# Vertex Database
# ============================================================================

# Vertex definitions: name, epsilon, mu, sigma, cgroup_slice, description
VERTICES="
V000:Neutrino:0:0:0:neutrino:Kernel microthreads and zero-overhead watchers
V001:Antineutrino:0:0:1:antineutrino:Kernel debug probes and eBPF tracing
V010:Neutron:0:1:0::Core kernel services (scheduler, memory, VFS)
V011:Antineutron:0:1:1::Kernel instrumentation and crash analysis
V100:Photon:1:0:0:photon:Lightweight user-space production daemons
V101:Antiphoton:1:0:1:antiphoton:Lightweight development tools
V110:Electron:1:1:0:electron:Full user-space production services
V111:Positron:1:1:1:positron:Debug and test environments
"

get_vertex_info() {
    local vertex_id="$1"
    echo "$VERTICES" | while IFS=: read -r id name eps mu sig slice desc; do
        [ -z "$id" ] && continue
        id="$(echo "$id" | tr -d ' ')"
        if [ "$id" = "$vertex_id" ]; then
            echo "${id}:${name}:${eps}:${mu}:${sig}:${slice}:${desc}"
            return 0
        fi
    done
}

get_vertex_state() {
    local vertex_id="$1"
    if [ -f "$STATE_FILE" ]; then
        local state
        state="$(grep "^${vertex_id}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2)"
        echo "${state:-unknown}"
    else
        echo "unknown"
    fi
}

# ============================================================================
# Commands
# ============================================================================

cmd_status() {
    local sigma
    sigma="$(cat "$CHIRALITY_FILE" 2>/dev/null || echo '?')"
    local boot_complete
    boot_complete="$(cat "${RUN_DIR}/boot-complete" 2>/dev/null || echo 'no')"

    printf "\n"
    printf "  Waterlight OS v%s -- Vertex Status\n" "$VERSION"
    printf "  ══════════════════════════════════════════\n"
    printf "  Chirality (sigma): %s (%s)\n" "$sigma" \
        "$([ "$sigma" = "0" ] && echo 'MATTER/PRODUCTION' || echo 'ANTIMATTER/DEVELOPMENT')"
    printf "  Boot complete: %s\n\n" \
        "$([ "$boot_complete" != "no" ] && echo "yes ($(date -d @"$boot_complete" 2>/dev/null || echo "$boot_complete"))" || echo "no")"

    printf "  %-6s %-15s %-3s %-3s %-3s %-10s %s\n" \
        "VERTEX" "NAME" "eps" "mu" "sig" "STATE" "DESCRIPTION"
    printf "  %-6s %-15s %-3s %-3s %-3s %-10s %s\n" \
        "------" "---------------" "---" "---" "---" "----------" "-------------------"

    echo "$VERTICES" | while IFS=: read -r id name eps mu sig slice desc; do
        [ -z "$id" ] && continue
        id="$(echo "$id" | tr -d ' ')"
        name="$(echo "$name" | tr -d ' ')"
        eps="$(echo "$eps" | tr -d ' ')"
        mu="$(echo "$mu" | tr -d ' ')"
        sig="$(echo "$sig" | tr -d ' ')"
        desc="$(echo "$desc" | sed 's/^[[:space:]]*//')"

        local state
        state="$(get_vertex_state "$id")"

        local state_color="$state"

        printf "  %-6s %-15s %-3s %-3s %-3s %-10s %s\n" \
            "$id" "$name" "$eps" "$mu" "$sig" "$state_color" "$desc"
    done

    printf "\n"
}

cmd_inspect() {
    local vertex_id="$1"
    if [ -z "$vertex_id" ]; then
        echo "Usage: waterlight-vertex inspect <vertex-id>"
        echo "Example: waterlight-vertex inspect V100"
        exit 1
    fi

    local info
    info="$(get_vertex_info "$vertex_id")"
    if [ -z "$info" ]; then
        echo "Error: Unknown vertex '${vertex_id}'"
        echo "Valid vertices: V000 V001 V010 V011 V100 V101 V110 V111"
        exit 1
    fi

    local name eps mu sig slice desc
    IFS=: read -r _ name eps mu sig slice desc <<EOF
$info
EOF

    printf "\n"
    printf "  Vertex: %s (%s)\n" "$vertex_id" "$name"
    printf "  ══════════════════════════════════════════\n"
    printf "  Coordinates:\n"
    printf "    epsilon (visibility): %s (%s)\n" "$eps" \
        "$([ "$eps" = "0" ] && echo 'kernel' || echo 'user')"
    printf "    mu (weight):          %s (%s)\n" "$mu" \
        "$([ "$mu" = "0" ] && echo 'lightweight' || echo 'heavyweight')"
    printf "    sigma (polarity):     %s (%s)\n" "$sig" \
        "$([ "$sig" = "0" ] && echo 'production' || echo 'development')"
    printf "  State: %s\n" "$(get_vertex_state "$vertex_id")"
    printf "  Description: %s\n" "$desc"

    # Chiral partner
    local partner_sig=$((1 - sig))
    local partner_id="V${eps}${mu}${partner_sig}"
    printf "  Chiral partner: %s\n" "$partner_id"

    # Adjacent vertices (differ by one axis)
    printf "  Adjacent vertices:\n"
    local adj_eps=$((1 - eps))
    local adj_mu=$((1 - mu))
    printf "    epsilon edge -> V%s%s%s\n" "$adj_eps" "$mu" "$sig"
    printf "    mu edge      -> V%s%s%s\n" "$eps" "$adj_mu" "$sig"
    printf "    sigma edge   -> V%s%s%s\n" "$eps" "$mu" "$partner_sig"

    # Cgroup info
    if [ -n "$slice" ] && [ -d "${CGROUP_BASE}/${slice}.slice" ]; then
        local slice_dir="${CGROUP_BASE}/${slice}.slice"
        printf "\n  Cgroup: waterlight.slice/%s.slice\n" "$slice"

        if [ -f "${slice_dir}/memory.current" ]; then
            local mem_current mem_max
            mem_current="$(cat "${slice_dir}/memory.current" 2>/dev/null || echo '?')"
            mem_max="$(cat "${slice_dir}/memory.max" 2>/dev/null || echo '?')"
            printf "    Memory: %s / %s\n" \
                "$(numfmt --to=iec "$mem_current" 2>/dev/null || echo "$mem_current")" \
                "$([ "$mem_max" = "max" ] && echo "unlimited" || numfmt --to=iec "$mem_max" 2>/dev/null || echo "$mem_max")"
        fi

        if [ -f "${slice_dir}/cpu.weight" ]; then
            printf "    CPU weight: %s\n" "$(cat "${slice_dir}/cpu.weight" 2>/dev/null || echo '?')"
        fi

        if [ -f "${slice_dir}/pids.current" ]; then
            local pids_current pids_max
            pids_current="$(cat "${slice_dir}/pids.current" 2>/dev/null || echo '?')"
            pids_max="$(cat "${slice_dir}/pids.max" 2>/dev/null || echo '?')"
            printf "    PIDs: %s / %s\n" "$pids_current" "$pids_max"
        fi
    elif [ -z "$slice" ]; then
        printf "\n  Cgroup: N/A (kernel-space vertex)\n"
    else
        printf "\n  Cgroup: not mounted\n"
    fi

    # Services in this vertex
    printf "\n  Services:\n"
    local found=0
    for pidfile in "${RUN_DIR}/membrane"/*.pid; do
        [ -f "$pidfile" ] || continue
        local svc
        svc="$(basename "$pidfile" .pid)"
        # Check fusion file for vertex assignment
        local fusion="${CONF_DIR}/fusion/${svc}.fusion"
        if [ -f "$fusion" ]; then
            local svc_vertex
            svc_vertex="$(grep '^vertex' "$fusion" | head -1 | cut -d= -f2 | tr -d ' ')"
            if [ "$svc_vertex" = "$vertex_id" ]; then
                local pid
                pid="$(cat "$pidfile" 2>/dev/null)"
                local running="dead"
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    running="running"
                fi
                printf "    %s (PID %s) [%s]\n" "$svc" "$pid" "$running"
                found=1
            fi
        fi
    done
    if [ "$found" -eq 0 ]; then
        printf "    (none)\n"
    fi

    printf "\n"
}

cmd_list() {
    echo "$VERTICES" | while IFS=: read -r id name eps mu sig slice desc; do
        [ -z "$id" ] && continue
        id="$(echo "$id" | tr -d ' ')"
        name="$(echo "$name" | tr -d ' ')"
        printf "%s %s\n" "$id" "$name"
    done
}

cmd_services() {
    local vertex_id="$1"

    printf "\n  Services by Vertex\n"
    printf "  ══════════════════════════════════════════\n\n"

    echo "$VERTICES" | while IFS=: read -r id name eps mu sig slice desc; do
        [ -z "$id" ] && continue
        id="$(echo "$id" | tr -d ' ')"
        name="$(echo "$name" | tr -d ' ')"

        if [ -n "$vertex_id" ] && [ "$id" != "$vertex_id" ]; then
            continue
        fi

        printf "  %s (%s):\n" "$id" "$name"

        local found=0
        for pidfile in "${RUN_DIR}/membrane"/*.pid; do
            [ -f "$pidfile" ] || continue
            local svc
            svc="$(basename "$pidfile" .pid)"
            local pid
            pid="$(cat "$pidfile" 2>/dev/null)"
            local running="dead"
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                running="running"
            fi
            printf "    %-20s PID %-8s [%s]\n" "$svc" "$pid" "$running"
            found=1
        done
        if [ "$found" -eq 0 ]; then
            printf "    (no services)\n"
        fi
        printf "\n"
    done
}

cmd_cube() {
    # ASCII art representation of the current cube state
    local s00 s01 s10 s11 s20 s21 s30 s31
    s00="$(get_vertex_state V000)"
    s01="$(get_vertex_state V001)"
    s10="$(get_vertex_state V010)"
    s11="$(get_vertex_state V011)"
    s20="$(get_vertex_state V100)"
    s21="$(get_vertex_state V101)"
    s30="$(get_vertex_state V110)"
    s31="$(get_vertex_state V111)"

    # State to symbol
    sym() {
        case "$1" in
            active)   printf "#" ;;
            pending)  printf "~" ;;
            inactive) printf "." ;;
            *)        printf "?" ;;
        esac
    }

    printf "\n"
    printf "  Z2-Cubed Cube State\n"
    printf "  ══════════════════════════════════════════\n\n"
    printf "  Legend: # active  ~ pending  . inactive  ? unknown\n\n"
    printf "          sigma=0        sigma=1\n"
    printf "          (matter)       (antimatter)\n"
    printf "          ┌──────┐       ┌──────┐\n"
    printf "  mu=1    │ %s V010│───────│ %s V011│   epsilon=0 (kernel)\n" "$(sym "$s10")" "$(sym "$s11")"
    printf "          │Neutron│       │AntiN  │\n"
    printf "          └──┬───┘       └──┬───┘\n"
    printf "             │               │\n"
    printf "          ┌──┴───┐       ┌──┴───┐\n"
    printf "  mu=0    │ %s V000│───────│ %s V001│   epsilon=0 (kernel)\n" "$(sym "$s00")" "$(sym "$s01")"
    printf "          │Neutri │       │AntiNu │\n"
    printf "          └──┬───┘       └──┬───┘\n"
    printf "             │ epsilon       │ epsilon\n"
    printf "          ┌──┴───┐       ┌──┴───┐\n"
    printf "  mu=0    │ %s V100│───────│ %s V101│   epsilon=1 (user)\n" "$(sym "$s20")" "$(sym "$s21")"
    printf "          │Photon │       │AntiPh │\n"
    printf "          └──┬───┘       └──┬───┘\n"
    printf "             │               │\n"
    printf "          ┌──┴───┐       ┌──┴───┐\n"
    printf "  mu=1    │ %s V110│───────│ %s V111│   epsilon=1 (user)\n" "$(sym "$s30")" "$(sym "$s31")"
    printf "          │Electr │       │Positr │\n"
    printf "          └──────┘       └──────┘\n"
    printf "\n"
}

# ============================================================================
# Main
# ============================================================================

usage() {
    cat <<EOF
waterlight-vertex v${VERSION} -- Vertex state management

Usage: waterlight-vertex <command> [args]

Commands:
  status              Show all vertex states and system info
  inspect <vertex>    Detailed inspection of a vertex (e.g., V100)
  list                List all vertices (machine-readable)
  services [vertex]   Show services organized by vertex
  cube                ASCII visualization of cube state
  help                Show this help

Vertices:
  V000 (Neutrino)       Kernel microthreads
  V001 (Antineutrino)   Kernel debug probes
  V010 (Neutron)        Core kernel services
  V011 (Antineutron)    Kernel instrumentation
  V100 (Photon)         Lightweight user daemons
  V101 (Antiphoton)     Dev tools (lightweight)
  V110 (Electron)       Full user services
  V111 (Positron)       Debug/test environments

EOF
}

case "${1:-status}" in
    status)   cmd_status ;;
    inspect)  cmd_inspect "$2" ;;
    list)     cmd_list ;;
    services) cmd_services "$2" ;;
    cube)     cmd_cube ;;
    help|-h|--help) usage ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
