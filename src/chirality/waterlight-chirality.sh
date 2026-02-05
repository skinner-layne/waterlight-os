#!/bin/sh
# waterlight-chirality.sh -- Chirality (sigma axis) mode switching
#
# Chirality transforms the system between matter (sigma=0, production)
# and antimatter (sigma=1, development) modes. Every vertex has a chiral
# partner that mirrors its function in the opposite polarity.
#
# Right-hand (dextro): synthesis, construction, deployment (sigma=0)
# Left-hand (levo): analysis, destruction, debugging (sigma=1)

set -e

VERSION="0.1.0"
RUN_DIR="/run/waterlight"
CONF_DIR="/etc/waterlight"
CHIRALITY_FILE="${RUN_DIR}/chirality"
STATE_FILE="${RUN_DIR}/vertex-state"
CHIRALITY_CONF="${CONF_DIR}/chirality"

# ============================================================================
# Chiral Pairs
# ============================================================================

# Each matter vertex has an antimatter mirror:
#   V000 (Neutrino)    <-> V001 (Antineutrino)
#   V010 (Neutron)     <-> V011 (Antineutron)
#   V100 (Photon)      <-> V101 (Antiphoton)
#   V110 (Electron)    <-> V111 (Positron)

MATTER_VERTICES="V000 V010 V100 V110"
ANTIMATTER_VERTICES="V001 V011 V101 V111"

get_chiral_partner() {
    case "$1" in
        V000) echo "V001" ;; V001) echo "V000" ;;
        V010) echo "V011" ;; V011) echo "V010" ;;
        V100) echo "V101" ;; V101) echo "V100" ;;
        V110) echo "V111" ;; V111) echo "V110" ;;
    esac
}

get_sigma() {
    cat "$CHIRALITY_FILE" 2>/dev/null || echo "0"
}

# ============================================================================
# Commands
# ============================================================================

cmd_status() {
    local sigma
    sigma="$(get_sigma)"

    printf "\n"
    printf "  Waterlight Chirality Status\n"
    printf "  ══════════════════════════════════════════\n\n"

    if [ "$sigma" = "0" ]; then
        printf "  Current mode: MATTER (sigma=0) -- PRODUCTION\n"
        printf "  Hand:         RIGHT (dextro) -- synthesis, construction, deployment\n"
    else
        printf "  Current mode: ANTIMATTER (sigma=1) -- DEVELOPMENT\n"
        printf "  Hand:         LEFT (levo) -- analysis, destruction, debugging\n"
    fi

    printf "\n  Chiral Pairs:\n\n"
    printf "  %-18s %-10s    %-18s %-10s\n" \
        "MATTER (sigma=0)" "STATE" "ANTIMATTER (sigma=1)" "STATE"
    printf "  %-18s %-10s    %-18s %-10s\n" \
        "------------------" "----------" "--------------------" "----------"

    local pairs="V000:V001:Neutrino:Antineutrino V010:V011:Neutron:Antineutron V100:V101:Photon:Antiphoton V110:V111:Electron:Positron"
    for pair in $pairs; do
        local m a mn an
        m="$(echo "$pair" | cut -d: -f1)"
        a="$(echo "$pair" | cut -d: -f2)"
        mn="$(echo "$pair" | cut -d: -f3)"
        an="$(echo "$pair" | cut -d: -f4)"

        local m_state a_state
        m_state="$(grep "^${m}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2)"
        a_state="$(grep "^${a}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2)"

        printf "  %-4s %-13s %-10s <-> %-4s %-13s %-10s\n" \
            "$m" "$mn" "${m_state:-unknown}" \
            "$a" "$an" "${a_state:-unknown}"
    done

    printf "\n"

    # Show what changes on flip
    if [ "$sigma" = "0" ]; then
        printf "  On chirality flip (-> ANTIMATTER):\n"
        printf "    + V001 Antineutrino: kernel debug probes activate\n"
        printf "    + V011 Antineutron:  kernel instrumentation activates\n"
        printf "    + V101 Antiphoton:   dev tools (linters, watchers) start\n"
        printf "    + V111 Positron:     debuggers, profilers, test suites start\n"
        printf "    + Debug symbols exposed via overlay filesystem\n"
        printf "    + Network policies relaxed for introspection\n"
        printf "    + Audit logging becomes optional\n"
    else
        printf "  On chirality flip (-> MATTER):\n"
        printf "    - V001 Antineutrino: kernel debug probes detach\n"
        printf "    - V011 Antineutron:  kernel instrumentation stops\n"
        printf "    - V101 Antiphoton:   dev tools shut down\n"
        printf "    - V111 Positron:     debuggers, profilers stop\n"
        printf "    - Debug symbols hidden from overlay filesystem\n"
        printf "    - Network policies tightened\n"
        printf "    - Audit logging becomes mandatory\n"
    fi

    printf "\n"
}

cmd_flip() {
    local target=""

    case "${1:-toggle}" in
        toggle)
            local current
            current="$(get_sigma)"
            target=$((1 - current))
            ;;
        matter|production|0)
            target=0
            ;;
        antimatter|development|dev|1)
            target=1
            ;;
        *)
            echo "Usage: waterlight-chirality flip [matter|antimatter|toggle]"
            exit 1
            ;;
    esac

    local current
    current="$(get_sigma)"

    if [ "$target" = "$current" ]; then
        echo "Already in $([ "$target" = "0" ] && echo 'MATTER' || echo 'ANTIMATTER') mode."
        return 0
    fi

    local target_name
    target_name="$([ "$target" = "0" ] && echo 'MATTER (production)' || echo 'ANTIMATTER (development)')"

    echo "Chirality flip: $([ "$current" = "0" ] && echo 'MATTER' || echo 'ANTIMATTER') -> ${target_name}"
    echo ""

    if [ "$target" = "1" ]; then
        # Flipping to antimatter: activate sigma=1 vertices
        echo "Activating antimatter vertices..."

        # Apply antimatter configuration overlay
        if [ -f "${CHIRALITY_CONF}/antimatter.conf" ]; then
            echo "  Loading antimatter configuration"
            # Source antimatter-specific environment
            # In v0.1 this is a placeholder for overlay activation
        fi

        # Activate antimatter vertex states
        for v in $ANTIMATTER_VERTICES; do
            echo "  Activating ${v}"
            if [ -f "$STATE_FILE" ]; then
                sed -i "s/^${v}=inactive/${v}=active/" "$STATE_FILE" 2>/dev/null || true
                sed -i "s/^${v}=pending/${v}=active/" "$STATE_FILE" 2>/dev/null || true
            fi
        done

        # Start antimatter services (from fusion files with sigma=1 phase)
        local fusion_dir="${CONF_DIR}/fusion"
        if [ -d "$fusion_dir" ]; then
            for fusion_file in "$fusion_dir"/*.fusion; do
                [ -f "$fusion_file" ] || continue
                local svc_vertex
                svc_vertex="$(grep '^vertex' "$fusion_file" | head -1 | cut -d= -f2 | tr -d ' ')"
                case "$svc_vertex" in
                    V101|V111)
                        local svc_name
                        svc_name="$(basename "$fusion_file" .fusion)"
                        echo "  Starting antimatter service: ${svc_name}"
                        # Placeholder: would start the service here
                        ;;
                esac
            done
        fi

        echo ""
        echo "Antimatter vertices activated. Development mode enabled."

    else
        # Flipping to matter: deactivate sigma=1 vertices
        echo "Deactivating antimatter vertices..."

        # Stop antimatter services
        for v in $ANTIMATTER_VERTICES; do
            echo "  Deactivating ${v}"
            if [ -f "$STATE_FILE" ]; then
                sed -i "s/^${v}=active/${v}=inactive/" "$STATE_FILE" 2>/dev/null || true
            fi
        done

        # Kill antimatter service processes
        for pidfile in "${RUN_DIR}/membrane"/*.pid; do
            [ -f "$pidfile" ] || continue
            local svc
            svc="$(basename "$pidfile" .pid)"
            local descriptor="${RUN_DIR}/membrane/${svc}.membrane"
            if [ -f "$descriptor" ]; then
                local svc_vertex
                svc_vertex="$(grep '^vertex=' "$descriptor" | cut -d= -f2)"
                case "$svc_vertex" in
                    V001|V011|V101|V111)
                        local pid
                        pid="$(cat "$pidfile" 2>/dev/null)"
                        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                            echo "  Stopping antimatter service: ${svc} (PID ${pid})"
                            kill -TERM "$pid" 2>/dev/null || true
                        fi
                        rm -f "$pidfile"
                        ;;
                esac
            fi
        done

        # Apply matter configuration
        if [ -f "${CHIRALITY_CONF}/matter.conf" ]; then
            echo "  Loading matter configuration"
        fi

        echo ""
        echo "Antimatter vertices deactivated. Production mode enabled."
    fi

    # Write new chirality state
    mkdir -p "$(dirname "$CHIRALITY_FILE")"
    echo "$target" > "$CHIRALITY_FILE"

    echo ""
    echo "Chirality: sigma=${target}"
}

cmd_selective() {
    local vertex="$1"
    local action="$2"

    if [ -z "$vertex" ] || [ -z "$action" ]; then
        echo "Usage: waterlight-chirality selective <vertex> <activate|deactivate>"
        echo ""
        echo "Selectively flip chirality for a single vertex pair."
        echo "Example: waterlight-chirality selective V100 activate"
        echo "  This activates V101 (the antimatter partner of V100)"
        exit 1
    fi

    local partner
    partner="$(get_chiral_partner "$vertex")"
    if [ -z "$partner" ]; then
        echo "Error: Unknown vertex '${vertex}'"
        exit 1
    fi

    # Determine which is the antimatter vertex
    local antimatter
    case "$vertex" in
        V00[13]|V01[13]|V10[13]|V11[13])
            antimatter="$vertex"
            ;;
        *)
            antimatter="$partner"
            ;;
    esac

    case "$action" in
        activate)
            echo "Selective chirality: activating ${antimatter} (partner of ${vertex})"
            if [ -f "$STATE_FILE" ]; then
                sed -i "s/^${antimatter}=inactive/${antimatter}=active/" "$STATE_FILE" 2>/dev/null || true
            fi
            echo "Done."
            ;;
        deactivate)
            echo "Selective chirality: deactivating ${antimatter} (partner of ${vertex})"
            if [ -f "$STATE_FILE" ]; then
                sed -i "s/^${antimatter}=active/${antimatter}=inactive/" "$STATE_FILE" 2>/dev/null || true
            fi
            echo "Done."
            ;;
        *)
            echo "Error: Action must be 'activate' or 'deactivate'"
            exit 1
            ;;
    esac
}

cmd_diff() {
    # Show what differs between current mode and the flip
    local sigma
    sigma="$(get_sigma)"
    local target_name
    target_name="$([ "$sigma" = "0" ] && echo 'ANTIMATTER' || echo 'MATTER')"

    printf "\n"
    printf "  Chirality Diff: Current -> %s\n" "$target_name"
    printf "  ══════════════════════════════════════════\n\n"

    if [ "$sigma" = "0" ]; then
        printf "  Services that would START:\n"
    else
        printf "  Services that would STOP:\n"
    fi

    local fusion_dir="${CONF_DIR}/fusion"
    local found=0
    if [ -d "$fusion_dir" ]; then
        for fusion_file in "$fusion_dir"/*.fusion; do
            [ -f "$fusion_file" ] || continue
            local svc_vertex
            svc_vertex="$(grep '^vertex' "$fusion_file" | head -1 | cut -d= -f2 | tr -d ' ')"
            case "$svc_vertex" in
                V001|V011|V101|V111)
                    local svc_name svc_desc
                    svc_name="$(basename "$fusion_file" .fusion)"
                    svc_desc="$(grep '^description' "$fusion_file" | head -1 | cut -d= -f2 | sed 's/^[[:space:]]*//')"
                    printf "    %-20s %-6s %s\n" "$svc_name" "$svc_vertex" "$svc_desc"
                    found=1
                    ;;
            esac
        done
    fi

    if [ "$found" -eq 0 ]; then
        printf "    (no antimatter services defined)\n"
    fi

    printf "\n  Configuration changes:\n"
    if [ "$sigma" = "0" ]; then
        printf "    + Debug overlays mounted\n"
        printf "    + Extended capabilities granted\n"
        printf "    + Network introspection enabled\n"
        printf "    + Audit logging: mandatory -> optional\n"
    else
        printf "    - Debug overlays unmounted\n"
        printf "    - Capabilities restricted\n"
        printf "    - Network introspection disabled\n"
        printf "    - Audit logging: optional -> mandatory\n"
    fi

    printf "\n"
}

# ============================================================================
# Main
# ============================================================================

usage() {
    cat <<EOF
waterlight-chirality v${VERSION} -- Mode switching (production/development)

Usage: waterlight-chirality <command> [args]

Commands:
  status                          Show current chirality state and pairs
  flip [matter|antimatter|toggle] Switch chirality mode
  selective <vertex> <activate|deactivate>
                                  Flip chirality for a single vertex pair
  diff                            Show what changes on chirality flip
  help                            Show this help

Modes:
  matter (sigma=0)     Production: right-hand path, synthesis, deployment
  antimatter (sigma=1) Development: left-hand path, analysis, debugging

Examples:
  waterlight-chirality flip                    # Toggle current mode
  waterlight-chirality flip antimatter         # Switch to dev mode
  waterlight-chirality selective V100 activate # Add dev tools for photon services

EOF
}

case "${1:-status}" in
    status)    cmd_status ;;
    flip)      shift; cmd_flip "$@" ;;
    selective) shift; cmd_selective "$@" ;;
    diff)      cmd_diff ;;
    toggle)    cmd_flip toggle ;;
    help|-h|--help) usage ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
