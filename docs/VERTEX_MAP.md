# Vertex Map: Z2-Cubed to OS Subsystems

## Coordinate System

Each vertex is addressed as V(epsilon)(mu)(sigma) where:
- epsilon in {0,1}: 0=kernel, 1=user
- mu in {0,1}: 0=lightweight, 1=heavyweight
- sigma in {0,1}: 0=production, 1=development

## V000 -- Neutrino

**Coordinates**: epsilon=0, mu=0, sigma=0
**Domain**: Kernel-space, lightweight, production
**Color**: Deep black (invisible, weightless, productive)

### Subsystem Role
The silent watchers of the kernel. Zero-overhead threads that react to events but hold no significant state. These are the quantum foam of the OS -- always present, barely detectable, essential.

### Components
- Kernel worker threads (kworker)
- Softirq handlers
- RCU callback processors
- Timer interrupt handlers
- Workqueue threads
- Completion handlers

### Properties
- **Lifetime**: kernel boot to shutdown
- **Memory**: negligible (kernel stack only)
- **CPU**: interrupt-driven, near-zero when idle
- **Isolation**: none needed (kernel space)
- **Observability**: /proc/softirqs, /proc/interrupts

### Cgroup Slice
`waterlight.slice/neutrino.slice` -- exists for accounting only, no enforcement.

---

## V001 -- Antineutrino

**Coordinates**: epsilon=0, mu=0, sigma=1
**Domain**: Kernel-space, lightweight, development
**Color**: Deep violet (barely visible, the observation complement of V000)

### Subsystem Role
The chiral mirror of V000. Where neutrinos do work, antineutrinos observe work being done. eBPF programs, kprobes, tracepoints -- lightweight kernel instrumentation that exists to make the invisible visible.

### Components
- eBPF programs (XDP, tc, kprobe, tracepoint, perf_event)
- ftrace infrastructure
- kprobes / kretprobes
- tracepoints (static and dynamic)
- perf event handlers

### Properties
- **Lifetime**: attached/detached dynamically
- **Memory**: per-program limits (eBPF verifier enforced)
- **CPU**: proportional to observed events
- **Isolation**: eBPF verifier sandbox
- **Observability**: bpftool, /sys/kernel/debug/tracing/

### Activation
V001 activates when chirality includes kernel-level observation. Not present in minimal production mode.

### Cgroup Slice
`waterlight.slice/antineutrino.slice`

---

## V010 -- Neutron

**Coordinates**: epsilon=0, mu=1, sigma=0
**Domain**: Kernel-space, heavyweight, production
**Color**: Granite (the structural bedrock)

### Subsystem Role
The load-bearing walls of the kernel. These are the complex, stateful subsystems that constitute the kernel's core functionality. Without neutrons, there is no OS -- only firmware.

### Components
- Process scheduler (CFS/EEVDF)
- Memory management (page allocator, slab, NUMA, compaction)
- Virtual Filesystem Switch (VFS)
- Block I/O layer
- Network stack (L2-L4)
- Device model and driver core
- Security framework (LSM hooks)

### Properties
- **Lifetime**: permanent (compiled-in or essential modules)
- **Memory**: significant (page tables, slab caches, buffer cache)
- **CPU**: on-demand, priority over all user-space
- **Isolation**: not applicable (these provide isolation to others)
- **Observability**: /proc/meminfo, /proc/stat, /proc/net/

### Notes
Neutrons are the only vertex that cannot be started or stopped -- they exist as long as the kernel runs. They ARE the kernel in its operational sense.

---

## V011 -- Antineutron

**Coordinates**: epsilon=0, mu=1, sigma=1
**Domain**: Kernel-space, heavyweight, development
**Color**: Blood red (exposing what is normally hidden)

### Subsystem Role
The chiral mirror of V010. Heavyweight kernel infrastructure that exists for analysis, debugging, and crash recovery. When something goes wrong in V010, V011 is what catches it.

### Components
- kdump / kexec crash handler
- kgdb kernel debugger
- KASAN (Address Sanitizer)
- KCSAN (Concurrency Sanitizer)
- KMEMLEAK (memory leak detector)
- lockdep (lock dependency validator)
- kernfs debug interfaces

### Properties
- **Lifetime**: compile-time or module-load
- **Memory**: significant (shadow memory for sanitizers)
- **CPU**: substantial overhead when active
- **Isolation**: integrated into kernel (cannot be isolated from it)
- **Observability**: dmesg, /sys/kernel/debug/

### Activation
V011 requires kernel compile-time options. A production kernel (sigma=0) typically lacks these. A development kernel (sigma=1) includes them. This is the deepest level of chirality -- it affects the kernel binary itself.

---

## V100 -- Photon

**Coordinates**: epsilon=1, mu=0, sigma=0
**Domain**: User-space, lightweight, production
**Color**: Clear white (visible, weightless, pure utility)

### Subsystem Role
The nimble production daemons. Event-driven, single-purpose, stateless or minimally-stateful services that form the connective tissue of the running system. Named for photons because they carry signals without mass.

### Components
- DNS stub resolver (e.g., unbound in forwarding mode)
- NTP client (e.g., chrony in client mode)
- Log forwarder (e.g., svlogd, socklog)
- Health check daemons
- Socket-activated services
- Cron scheduler (e.g., crond)
- D-Bus broker (if needed)
- mDNS responder

### Properties
- **Lifetime**: long-running but easily replaceable
- **Memory**: < 64MB per service
- **CPU**: < 0.5 CPU share
- **Isolation**: full namespace isolation by default
- **Observability**: structured logs, health endpoints

### Cgroup Slice
`waterlight.slice/photon.slice`
- Memory soft limit: 64M
- Memory hard limit: 128M
- CPU shares: 256
- IO weight: 100

### Membrane Profile
Tight isolation, minimal capabilities. The photon membrane is the default and most restrictive user-space membrane.

---

## V101 -- Antiphoton

**Coordinates**: epsilon=1, mu=0, sigma=1
**Domain**: User-space, lightweight, development
**Color**: Ultraviolet (just beyond visible, the dev complement of V100)

### Subsystem Role
Lightweight development tools that observe or assist production daemons. File watchers, linters, formatters, language servers -- tools that are small but essential for the development workflow.

### Components
- File watchers (entr, watchexec, inotifywait)
- Linters (shellcheck, hadolint)
- Formatters (shfmt, prettier)
- Language servers (LSP implementations)
- Hot-reload proxies
- REPL environments
- Documentation generators

### Properties
- **Lifetime**: session-bound (activated with dev mode)
- **Memory**: < 64MB per tool
- **CPU**: burst-oriented (runs on file change, then idles)
- **Isolation**: partial (needs to observe V100 processes)
- **Observability**: stdout/stderr, structured output

### Cgroup Slice
`waterlight.slice/antiphoton.slice`
- Same limits as V100 but with CAP_SYS_PTRACE for observation

### Membrane Profile
Derived from V100 but with relaxed PID namespace (can see V100 processes) and additional capabilities for tracing.

---

## V110 -- Electron

**Coordinates**: epsilon=1, mu=1, sigma=0
**Domain**: User-space, heavyweight, production
**Color**: Copper (conductive, substantial, the workhorse of circuits)

### Subsystem Role
The full-weight production services. Databases, web servers, application runtimes, message brokers. These are the services that users and applications directly interact with. Named for electrons because they carry the charge -- the actual work of the system.

### Components
- Databases (PostgreSQL, SQLite, Redis)
- Web servers (nginx, caddy)
- Application runtimes (Node.js, Python, Go, Rust binaries)
- Message brokers (NATS, mosquitto)
- Container runtimes (podman, containerd)
- Reverse proxies / load balancers

### Properties
- **Lifetime**: long-running, stateful, managed restarts
- **Memory**: configurable per-service, typically 256M-4G
- **CPU**: configurable per-service, typically 1-4 CPU
- **Isolation**: per-service namespaces with controlled sharing
- **Observability**: metrics endpoints, structured logs, traces

### Cgroup Slice
`waterlight.slice/electron.slice`
- Memory: per-service configuration
- CPU: per-service configuration
- IO: per-service configuration with proportional weights

### Membrane Profile
Per-service membrane with full customization. Each electron service gets its own membrane definition specifying exact namespace, cgroup, and capability configuration.

---

## V111 -- Positron

**Coordinates**: epsilon=1, mu=1, sigma=1
**Domain**: User-space, heavyweight, development
**Color**: Gold (the most visible, most substantial development vertex)

### Subsystem Role
The full-weight development and debugging infrastructure. Test suites, profilers, debuggers, fuzzers -- everything needed to analyze, test, and validate the electron services. Named for positrons because they are the antimatter complement of electrons.

### Components
- Debuggers (gdb, lldb, delve)
- Profilers (perf, flamegraph, pprof)
- Memory analyzers (valgrind, heaptrack)
- Fuzzers (AFL++, libFuzzer)
- Test runners (pytest, go test, cargo test)
- Integration test harnesses
- Load generators (k6, wrk, hey)
- Chaos engineering tools

### Properties
- **Lifetime**: session-bound or CI-bound
- **Memory**: generous (profilers need headroom)
- **CPU**: may need full system access for benchmarks
- **Isolation**: intentionally weakened (needs to observe V110)
- **Observability**: produces observability data for V110

### Cgroup Slice
`waterlight.slice/positron.slice`
- Generous limits, may be exempt from some restrictions
- CAP_SYS_PTRACE, CAP_SYS_ADMIN for full debugging access

### Membrane Profile
The most permissive user-space membrane. Explicitly allows cross-namespace observation of V110 services.

---

## Adjacency Matrix (Edges)

```
        V000  V001  V010  V011  V100  V101  V110  V111
V000     -     sigma  mu    -     eps   -      -     -
V001   sigma    -     -     mu    -     eps    -     -
V010    mu      -     -    sigma  -     -     eps    -
V011     -     mu   sigma   -     -     -      -    eps
V100    eps     -     -      -    -    sigma   mu    -
V101     -     eps    -      -   sigma  -      -    mu
V110     -      -    eps     -    mu    -      -   sigma
V111     -      -     -     eps   -     mu   sigma  -
```

Each edge represents a single-axis transition. Traversing an edge requires only one membrane adjustment.
