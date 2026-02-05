# Waterlight OS Architecture Specification

**Version 0.1 -- Genesis**

## 1. Foundational Theory

### 1.1 The Z2-Cubed Symmetry Group

The architecture of Waterlight OS is derived from Z2 x Z2 x Z2, the direct product of three copies of the cyclic group of order 2. This produces a cube with 8 vertices, 12 edges, 6 faces, and 1 interior. Each structural element maps to an OS concept.

The three generating axes:

- **epsilon (Visibility)**: kernel-space (0) vs user-space (1)
- **mu (Weight)**: lightweight/ephemeral (0) vs heavyweight/persistent (1)
- **sigma (Polarity)**: production/matter (0) vs development/antimatter (1)

### 1.2 Architectural Ontology

| Geometric Element | Count | OS Mapping |
|-------------------|-------|------------|
| Vertices | 8 | Subsystem classes (see Section 2) |
| Edges | 12 | Interfaces between adjacent subsystems |
| Faces | 6 | Planes of symmetry / policy domains |
| Interior | 1 | The Alpha Frame (pre-cubic kernel) |

### 1.3 Faces as Policy Domains

Each face of the cube is defined by fixing one axis:

| Face | Fixed Axis | Policy Domain |
|------|-----------|---------------|
| epsilon=0 | Kernel space | Ring 0 security policy |
| epsilon=1 | User space | User isolation policy |
| mu=0 | Lightweight | Resource limits (tight) |
| mu=1 | Heavyweight | Resource limits (generous) |
| sigma=0 | Production | Stability and audit policy |
| sigma=1 | Development | Permissiveness and observability policy |

### 1.4 Edges as Interfaces

An edge connects two vertices that differ in exactly one axis. This means the interface between them involves exactly one type of transition:

- **epsilon edges** (4 total): syscall boundary, kernel-user transitions
- **mu edges** (4 total): resource scaling, cgroup promotion/demotion
- **sigma edges** (4 total): chirality flips, dev/prod mode transitions

## 2. The Eight Vertices

### V000 -- Neutrino (Dark, Massless, Matter)
**Kernel microthreads and zero-overhead watchers.**

The lightest possible kernel-space entity. These are the kthreads, softirqs, and tasklets that exist purely as event reactors. They have no persistent state, no significant memory footprint, and operate in production mode.

- Implementation: kernel threads, workqueues, interrupt handlers
- Cgroup: `waterlight.slice/neutrino.slice` -- minimal limits
- Capabilities: none needed (already in kernel)
- Examples: timer interrupt handlers, page reclaim kthread, RCU callbacks

### V001 -- Antineutrino (Dark, Massless, Antimatter)
**Kernel debug probes and tracing.**

The mirror of V000. Same lightweight kernel presence but in observation/analysis mode rather than production. eBPF programs live here -- they are kernel-space, ephemeral, but exist to observe rather than produce.

- Implementation: eBPF probes, kprobes, tracepoints, ftrace
- Cgroup: `waterlight.slice/antineutrino.slice`
- Capabilities: CAP_BPF, CAP_PERFMON
- Examples: `bpftrace` probes, perf events, kernel tracepoints

### V010 -- Neutron (Dark, Massive, Matter)
**Core kernel services.**

The heavyweight kernel subsystems that constitute the structural foundation: the scheduler, memory manager, VFS, network stack, block layer. These are massive (complex, stateful) and dark (kernel-space) and matter (production-essential).

- Implementation: kernel subsystems compiled in or as essential modules
- Cgroup: not applicable (these ARE the cgroup infrastructure)
- Capabilities: these GRANT capabilities to others
- Examples: CFS scheduler, SLAB allocator, ext4/btrfs, netfilter

### V011 -- Antineutron (Dark, Massive, Antimatter)
**Kernel instrumentation and crash analysis.**

The mirror of V010. Heavyweight kernel-space infrastructure that exists for analysis rather than production. Crash dump mechanisms, kernel debuggers, instrumentation frameworks.

- Implementation: kdump, kgdb, lockdep, KASAN, KCSAN
- Cgroup: not applicable (kernel infrastructure)
- Capabilities: these are the analysis complement of V010
- Examples: crash dumps, lock dependency tracking, sanitizers, KMEMLEAK

### V100 -- Photon (Light, Massless, Matter)
**Lightweight user-space daemons.**

The workhorses of production user-space. Event-driven daemons, single-purpose services, sidecar processes. They are visible (user-space), lightweight (minimal resources), and productive (matter).

- Implementation: small daemons, event loops, socket activators
- Cgroup: `waterlight.slice/photon.slice` -- tight limits (64MB RAM, 0.5 CPU)
- Capabilities: minimal (CAP_NET_BIND_SERVICE at most)
- Namespace: full isolation (pid, net, mnt, uts, ipc, user)
- Examples: DNS resolver, NTP client, log forwarder, health checker

### V101 -- Antiphoton (Light, Massless, Antimatter)
**Lightweight development tools.**

The mirror of V100. Small user-space tools that exist for development, not production. Linters, formatters, file watchers, hot-reload daemons.

- Implementation: development utilities, watchers, generators
- Cgroup: `waterlight.slice/antiphoton.slice` -- tight limits
- Capabilities: may need CAP_SYS_PTRACE for debugging
- Namespace: shared with target (needs to observe V100 processes)
- Examples: `entr`, `watchexec`, `shellcheck`, language servers

### V110 -- Electron (Light, Massive, Matter)
**Full user-space services.**

Production applications that require significant resources. Databases, web servers, application servers, message brokers. Visible, heavy, and productive.

- Implementation: full server processes, managed by init
- Cgroup: `waterlight.slice/electron.slice` -- generous limits (configurable)
- Capabilities: per-service capability set
- Namespace: per-service isolation with controlled sharing
- Examples: PostgreSQL, nginx, Redis, application runtimes

### V111 -- Positron (Light, Massive, Antimatter)
**Debug and test environments.**

The mirror of V110. Full-weight user-space infrastructure that exists for testing, profiling, and debugging. Complete test harnesses, profiling suites, fuzzing infrastructure.

- Implementation: test runners, profilers, debuggers
- Cgroup: `waterlight.slice/positron.slice` -- generous limits
- Capabilities: broad (CAP_SYS_PTRACE, CAP_SYS_ADMIN for profiling)
- Namespace: may break isolation intentionally for observation
- Examples: `gdb`, `valgrind`, `perf`, `strace`, test suites, fuzzers

## 3. The Alpha Frame

### 3.1 Pre-Cubic Condition

Before the cube instantiates, there is the Alpha Frame. This is:
- The bootloader (GRUB/syslinux/EFISTUB)
- The kernel image
- The initramfs
- PID 1 (waterlight-init)

The Alpha Frame is hydrogen -- the simplest element, from which all others are synthesized. It exists prior to the vertex classification system. Its sole purpose is to bring the cube into existence.

### 3.2 Boot Sequence: Nucleosynthesis

```
BIOS/UEFI
  |
  v
Alpha Frame (bootloader)
  |
  v
Kernel (compressed, self-extracting)
  |
  v
initramfs (minimal root with waterlight-init)
  |
  v
waterlight-init (PID 1)
  |
  +---> Phase 1: HYDROGEN
  |     Mount essential filesystems (/proc, /sys, /dev, /run)
  |     Load kernel modules for hardware
  |     Mount real root filesystem
  |     Pivot root
  |
  +---> Phase 2: HELIUM FUSION
  |     Create cgroup hierarchy (waterlight.slice)
  |     Establish vertex slices (neutrino, photon, electron, etc.)
  |     Configure namespace templates
  |     Set system hostname, clock, entropy
  |
  +---> Phase 3: CARBON FUSION
  |     Start V000 services (kernel watchers: udevd, klogd)
  |     Start V100 services (lightweight daemons: syslogd, crond, networkd)
  |     Apply firewall/security policy
  |
  +---> Phase 4: OXYGEN FUSION
  |     Start V110 services (heavyweight: databases, servers)
  |     Apply per-service membranes (namespaces, cgroups, caps)
  |     If sigma=1 (dev mode): also start V101 and V111 services
  |
  +---> Phase 5: IRON CEILING
        System is fully operational.
        No further automatic fusion -- manual service management only.
        (Iron = the limit of exothermic fusion = the limit of automatic startup)
```

### 3.3 The Iron Ceiling

In stellar nucleosynthesis, iron is the heaviest element producible by fusion. Beyond iron requires supernova conditions -- external energy input. In Waterlight OS, the Iron Ceiling is the boundary between automatic boot services and manually-managed services. The system boots to a known, stable state. Anything beyond requires explicit operator action.

## 4. Membrane Architecture

### 4.1 Principle

A membrane in Waterlight is not a firewall. It is a selective, permeable boundary that can:
- **Stretch**: allow temporary resource expansion
- **Contract**: enforce tighter isolation under pressure
- **Breathe**: oscillate permeability based on trust signals
- **Rupture**: fail open or fail closed based on policy

### 4.2 Implementation Layers

| Layer | Mechanism | Controls |
|-------|-----------|----------|
| Process isolation | Linux namespaces | What a process can see |
| Resource limits | cgroups v2 | What a process can consume |
| Permission surface | Capabilities | What a process can do |
| Filesystem view | Mount namespaces + overlayfs | What a process can access |
| Network boundary | Network namespaces + nftables | What a process can reach |

### 4.3 Membrane Elasticity

Each membrane has a configured elasticity profile:

```yaml
# /etc/waterlight/membrane/photon.yaml
vertex: V100
isolation:
  pid_namespace: private        # own PID space
  net_namespace: shared:bridge0  # shared via bridge
  mnt_namespace: private        # own mount tree
  user_namespace: mapped         # UID mapping
resources:
  memory:
    soft: 64M
    hard: 128M       # membrane stretches from 64M to 128M
    swap: 0          # no swap (massless = no persistence spillover)
  cpu:
    shares: 256
    burst: 512       # can burst to 2x normal
  io:
    weight: 100
capabilities:
  granted:
    - CAP_NET_BIND_SERVICE
  ambient:
    - CAP_NET_BIND_SERVICE
  denied:
    - CAP_SYS_ADMIN
    - CAP_SYS_PTRACE
elasticity:
  stretch_trigger: load_avg > 0.8  # when to allow burst
  contract_trigger: memory > soft   # when to push back
  breathe_interval: 30s             # check interval
  rupture_policy: fail_closed       # on membrane failure
```

### 4.4 Vertex Transitions

A process can transition between vertices by requesting a membrane change. The transition must traverse exactly one edge (one axis flip at a time):

- V100 -> V110: lightweight daemon requests more resources (mu flip)
- V100 -> V101: production daemon enters debug mode (sigma flip)
- V100 -> V000: user daemon requests kernel-space operation (epsilon flip -- rare, via eBPF)

Multi-axis transitions require intermediate steps or explicit authorization.

## 5. Chirality System

### 5.1 The Sigma Axis

Every vertex has a chiral partner (its sigma-complement):

| Matter (sigma=0) | Antimatter (sigma=1) |
|-------------------|----------------------|
| V000 Neutrino | V001 Antineutrino |
| V010 Neutron | V011 Antineutron |
| V100 Photon | V101 Antiphoton |
| V110 Electron | V111 Positron |

### 5.2 Chirality Flip

A chirality flip transforms an entire plane of the cube:
- All sigma=0 services gain their sigma=1 companions
- Debug/trace/profile infrastructure activates alongside production
- Filesystem overlays expose source code, debug symbols, test data
- Network policies relax to allow introspection

This is NOT a separate environment. It is the same system with the antimatter axis activated. Production services keep running; development services join them.

### 5.3 Selective Chirality

Chirality can be flipped per-vertex rather than system-wide:
- Flip only V100->V101: add dev tools for lightweight daemons
- Flip only V110->V111: add profiling for heavyweight services
- Full flip: activate all antimatter vertices simultaneously

### 5.4 Implementation

Chirality is implemented via:
1. Service unit files with `sigma=0` and `sigma=1` variants
2. Overlayfs layers that expose/hide development assets
3. Capability grants that expand/contract the permission surface
4. Network namespace adjustments for debug traffic

## 6. The Periodic Table of Services

### 6.1 Hydrogen Primitives

The irreducible building blocks from which all services are composed:

| Primitive | Description |
|-----------|-------------|
| `h-socket` | A listening socket |
| `h-timer` | A periodic trigger |
| `h-watch` | A filesystem event watcher |
| `h-pipe` | A data pipeline stage |
| `h-store` | A key-value state holder |
| `h-gate` | An access control check |
| `h-log` | A structured log emitter |
| `h-signal` | An inter-process signal |

### 6.2 Fusion Rules

Services are defined as fusions of hydrogen primitives:

```
# DNS resolver (Photon / V100)
dns-resolver = h-socket(udp:53) + h-store(cache) + h-pipe(upstream) + h-log
Element number: 3 (Lithium -- 3 core primitives fused)

# Web server (Electron / V110)
web-server = h-socket(tcp:80,443) + h-store(config) + h-pipe(backend)
           + h-gate(tls) + h-gate(auth) + h-log + h-timer(keepalive)
Element number: 8 (Oxygen -- 8 primitives fused)

# Database (Electron / V110)
database = h-socket(tcp:5432) + h-store(btree) + h-store(wal)
         + h-gate(auth) + h-gate(acl) + h-log + h-timer(checkpoint)
         + h-pipe(replication) + h-watch(config)
Element number: 10 (Neon -- 10 primitives fused)
```

### 6.3 The Iron Ceiling in Service Terms

Services with element number <= 26 (iron) can be auto-started at boot. Services beyond 26 require manual instantiation. This maps directly to the boot phase model: hydrogen through iron is automatic nucleosynthesis.

## 7. Resource Flow: Kenosis

### 7.1 Principle

Resources flow outward from the kernel (V000/V010) toward user-space services (V100/V110). The kernel "empties itself" (kenosis) to enable user workloads. This is the opposite of a kernel that hoards resources for its own subsystems.

### 7.2 Implementation

- **Memory**: Kernel reserves only what it needs. `vm.min_free_kbytes` set low. Page cache aggressively reclaimed for user demands.
- **CPU**: Kernel threads run at minimal priority unless handling interrupts. User workloads get priority.
- **I/O**: Kernel I/O (journaling, metadata) yields to user I/O when contended.
- **Capabilities**: The kernel starts with all capabilities and progressively drops them as user services claim their subset.

### 7.3 Kenotic Flow Diagram

```
V010 (Neutron/Kernel Core)
  |
  | Capabilities flow outward
  | Resources flow outward
  | Control flows outward
  |
  +---> V000 (Neutrino) -- kernel watchers get minimal allocation
  |
  +---> V100 (Photon) -- lightweight daemons get tight but fair allocation
  |
  +---> V110 (Electron) -- heavy services get generous allocation
  |
  +---> [sigma=1 vertices get whatever their matter-twin has]
```

## 8. Security Model

### 8.1 Capability-Based Security

Waterlight uses Linux capabilities as its primary security mechanism, not traditional DAC or MAC (though these can layer on top). Each vertex has a capability profile:

| Vertex | Default Capabilities |
|--------|---------------------|
| V000 | All (kernel) |
| V001 | All + BPF-specific |
| V010 | All (kernel) |
| V011 | All + debug-specific |
| V100 | Minimal (NET_BIND_SERVICE) |
| V101 | V100 + SYS_PTRACE |
| V110 | Per-service set |
| V111 | V110 + SYS_PTRACE + SYS_ADMIN |

### 8.2 Membrane-Based Isolation

Security is enforced at membrane boundaries, not at the process level. A process that crosses a membrane boundary gets its capabilities adjusted automatically.

### 8.3 Sigma Security Differential

Antimatter vertices (sigma=1) are inherently more permissive. This is by design -- development/debug needs broader access. The security model accounts for this:

- Production (sigma=0): audit logging mandatory, capability set minimal
- Development (sigma=1): audit logging optional, capability set expanded
- Chirality flip activates/deactivates these policies atomically

## 9. Filesystem Layout

```
/
├── alpha/              Alpha Frame artifacts (bootloader, kernel, initramfs)
├── etc/
│   └── waterlight/
│       ├── system.conf          Global config (current sigma, hostname, etc.)
│       ├── vertices/            Per-vertex configuration
│       │   ├── V000.conf
│       │   ├── V001.conf
│       │   └── ...
│       ├── membrane/            Membrane profiles
│       │   ├── photon.yaml
│       │   ├── electron.yaml
│       │   └── ...
│       ├── chirality/           Chirality-specific overrides
│       │   ├── matter.conf      sigma=0 overrides
│       │   └── antimatter.conf  sigma=1 overrides
│       ├── fusion/              Service fusion definitions
│       │   ├── dns-resolver.fusion
│       │   ├── web-server.fusion
│       │   └── ...
│       └── periodic-table.conf  Service classification registry
├── run/
│   └── waterlight/
│       ├── vertex-state         Runtime vertex states
│       ├── membrane/            Active membrane descriptors
│       └── chirality            Current chirality mode
├── var/
│   └── waterlight/
│       ├── log/                 Vertex-organized logs
│       └── state/               Persistent state
└── usr/
    └── lib/
        └── waterlight/
            ├── alpha-frame/     Init system
            ├── vertex/          Vertex management
            ├── membrane/        Membrane tools
            └── chirality/       Mode switching
```

## 10. Future Directions

### 10.1 v0.2 -- Deuterium
- Working initramfs with waterlight-init
- Cgroup v2 hierarchy auto-creation
- Basic vertex state tracking

### 10.2 v0.3 -- Helium
- Membrane profiles enforced via namespace creation
- Chirality flip working end-to-end
- Service fusion DSL parser

### 10.3 v0.4 -- Lithium
- First "fused" service definitions
- Periodic table registry
- Vertex transition protocol

### 10.4 v1.0 -- Carbon
- Full boot sequence (hydrogen through iron)
- Live chirality switching
- Membrane elasticity (adaptive cgroups)
- Vertex-aware service manager
- Installable ISO image
