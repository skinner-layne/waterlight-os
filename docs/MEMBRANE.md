# Membrane Architecture

## Principle

In Waterlight OS, boundaries between subsystems are not firewalls -- they are membranes. A membrane is a dynamic, adaptive boundary that controls the flow of resources, signals, and capabilities between vertices of the Z2-cubed cube.

The biological metaphor is precise: a cell membrane is selectively permeable, responds to environmental signals, can stretch under pressure, and fails in defined ways. Waterlight membranes behave identically.

## Membrane Properties

### Permeability

What can cross the membrane and under what conditions.

| Flow Type | Mechanism | Control |
|-----------|-----------|---------|
| Data | Pipes, sockets, shared memory | Namespace boundaries |
| Signals | Unix signals, D-Bus, eventfd | PID namespace + capabilities |
| Resources | Memory, CPU, I/O | Cgroup limits |
| Capabilities | Privilege escalation/drop | Capability bounding set |
| Filesystem | File access | Mount namespace + overlayfs |
| Network | Packets | Network namespace + nftables |

### Elasticity

Membranes can stretch and contract in response to load.

```yaml
elasticity:
  memory:
    soft: 64M           # Normal operating limit
    hard: 128M          # Maximum stretch
    oom_kill: true       # Rupture behavior: kill process
  cpu:
    shares: 256          # Normal allocation
    burst: 512           # Stretch allocation
    burst_duration: 30s  # How long stretch is allowed
  io:
    weight: 100          # Normal I/O priority
    burst_weight: 200    # Under stretch
```

When a service exceeds its soft limit, the membrane stretches toward the hard limit. If the stretch is sustained, the membrane signals the vertex manager, which can:
1. Allow the stretch (promote to a heavier vertex)
2. Deny the stretch (enforce the hard limit)
3. Redistribute resources from other membranes

### Breathing

Membranes oscillate their permeability based on trust signals.

```yaml
breathing:
  interval: 30s
  trust_signals:
    - metric: error_rate
      threshold: 0.01      # > 1% errors = contract
      action: contract
    - metric: latency_p99
      threshold: 100ms     # > 100ms p99 = stretch
      action: stretch
    - metric: security_events
      threshold: 1         # Any security event = contract hard
      action: contract_hard
```

### Rupture

When a membrane fails, it can:

- **Fail closed**: Kill the contained process, log the event. Default for production (sigma=0).
- **Fail open**: Allow the violation, alert the operator. Default for development (sigma=1).
- **Fail loud**: Trigger a system-wide alert. For security-critical membranes.

## Implementation Stack

### Layer 1: Linux Namespaces

Each namespace type maps to a dimension of isolation:

| Namespace | Isolates | Membrane Role |
|-----------|----------|---------------|
| PID | Process tree | Who can you see? |
| Network | Network stack | Who can you talk to? |
| Mount | Filesystem tree | What can you access? |
| UTS | Hostname/domainname | Who are you? |
| IPC | System V IPC, POSIX MQ | Who can you signal? |
| User | UID/GID mapping | What identity do you have? |
| Cgroup | Cgroup root | What resources are yours? |
| Time | System clock (kernel 5.6+) | What time is it for you? |

### Layer 2: Cgroups v2

Resource accounting and limits. Waterlight uses the unified cgroup v2 hierarchy:

```
/sys/fs/cgroup/
  waterlight.slice/
    neutrino.slice/         # V000 kernel watchers
    antineutrino.slice/     # V001 kernel probes
    photon.slice/           # V100 lightweight production
      dns-resolver/
      ntp-client/
      log-forwarder/
    antiphoton.slice/       # V101 lightweight dev
    electron.slice/         # V110 heavyweight production
      postgresql/
      nginx/
      app-server/
    positron.slice/         # V111 heavyweight dev
      debugger/
      profiler/
```

Controllers enabled per-vertex:
- **memory**: soft/hard limits, swap control, OOM priority
- **cpu**: shares, bandwidth limiting, burst
- **io**: weight-based and bandwidth limiting
- **pids**: maximum process count

### Layer 3: Linux Capabilities

Fine-grained privilege control replacing the all-or-nothing root model.

Waterlight defines capability profiles per vertex:

```bash
# V100 (Photon) - minimal capabilities
CAPS_PHOTON="cap_net_bind_service"

# V101 (Antiphoton) - photon + debug
CAPS_ANTIPHOTON="cap_net_bind_service,cap_sys_ptrace"

# V110 (Electron) - per-service
CAPS_ELECTRON="<defined in fusion file>"

# V111 (Positron) - broad for debugging
CAPS_POSITRON="cap_sys_ptrace,cap_sys_admin,cap_dac_read_search"
```

### Layer 4: Overlayfs

Filesystem membrane that controls what a process can see and modify:

```
Lower layer:  /usr/lib/waterlight/rootfs/base/    (read-only base)
Middle layer: /usr/lib/waterlight/rootfs/vertex/   (vertex-specific additions)
Upper layer:  /var/waterlight/state/<service>/      (writable state)
Merged:       visible to the service
```

For chirality (sigma) flips:
```
sigma=0 overlay: base + vertex(matter)
sigma=1 overlay: base + vertex(matter) + vertex(antimatter)
```

Development mode adds an extra overlay layer with source code, debug symbols, and dev tools -- without modifying the production layers beneath.

## Membrane Profiles

### Profile: Vacuum (No Membrane)

For V000/V010 kernel-space vertices. No user-space isolation because the process IS the kernel.

### Profile: Photon (Tight)

```yaml
name: photon
vertex: V100
namespaces:
  pid: private
  net: private
  mnt: private
  uts: private
  ipc: private
  user: mapped
  cgroup: private
cgroup:
  memory.max: 128M
  memory.high: 64M
  memory.swap.max: 0
  cpu.weight: 25
  cpu.max: "50000 100000"  # 50% of one CPU
  pids.max: 64
capabilities:
  bounding: [cap_net_bind_service]
  ambient: [cap_net_bind_service]
seccomp: default-restrict
filesystem:
  root: overlay
  writable_paths: [/var/waterlight/state/$SERVICE, /tmp]
  read_only_paths: [/usr, /lib, /etc]
  hidden_paths: [/proc/kcore, /proc/kallsyms, /sys/firmware]
```

### Profile: Electron (Configurable)

```yaml
name: electron
vertex: V110
namespaces:
  pid: private
  net: per-service          # May share via bridge
  mnt: private
  uts: private
  ipc: per-service          # May share for IPC clusters
  user: mapped
  cgroup: private
cgroup:
  memory.max: "${SERVICE_MEMORY_MAX:-1G}"
  memory.high: "${SERVICE_MEMORY_HIGH:-512M}"
  memory.swap.max: "${SERVICE_SWAP_MAX:-0}"
  cpu.weight: "${SERVICE_CPU_WEIGHT:-100}"
  cpu.max: "${SERVICE_CPU_MAX:-max}"
  pids.max: "${SERVICE_PIDS_MAX:-4096}"
capabilities:
  bounding: "${SERVICE_CAPS}"
  ambient: "${SERVICE_AMBIENT_CAPS}"
seccomp: "${SERVICE_SECCOMP:-default-restrict}"
filesystem:
  root: overlay
  writable_paths: "${SERVICE_WRITABLE}"
  volumes: "${SERVICE_VOLUMES}"
```

### Profile: Positron (Permissive)

```yaml
name: positron
vertex: V111
namespaces:
  pid: shared-with-electron    # Can see V110 processes
  net: shared-with-electron    # Can reach V110 services
  mnt: private-with-debug      # Has debug symbols, source
  uts: private
  ipc: shared-with-electron
  user: mapped
  cgroup: private
cgroup:
  memory.max: 4G              # Generous for profiling
  memory.high: 2G
  cpu.weight: 200             # Priority for debugging
  cpu.max: max
  pids.max: 16384
capabilities:
  bounding: [cap_sys_ptrace, cap_sys_admin, cap_dac_read_search,
             cap_net_admin, cap_ipc_lock]
  ambient: [cap_sys_ptrace]
seccomp: permissive            # Debuggers need broad syscall access
```

## Membrane Operations

### Create

```bash
waterlight-membrane create <service-name> --vertex <vertex> [--profile <profile>]
```

Creates namespace, cgroup, and capability configuration for a new service.

### Inspect

```bash
waterlight-membrane inspect <service-name>
```

Shows current membrane state: namespace IDs, cgroup usage, active capabilities.

### Stretch

```bash
waterlight-membrane stretch <service-name> --memory 256M --duration 5m
```

Temporarily expands membrane limits. Automatically contracts after duration.

### Contract

```bash
waterlight-membrane contract <service-name> --memory 32M
```

Tightens membrane limits. Existing excess is reclaimed.

### Rupture

```bash
waterlight-membrane rupture <service-name> [--fail-closed | --fail-open]
```

Forces a membrane failure for testing or emergency response.

### Transition

```bash
waterlight-membrane transition <service-name> --from V100 --to V110
```

Migrates a service from one vertex to another, adjusting membrane accordingly.
