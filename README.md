# Waterlight OS

**A Linux distribution designed from first principles using the Z2-cubed theory framework.**

Waterlight OS is not another Linux distro. It is an operating system architecture derived from a unified physical-philosophical model -- the Z2-cubed cube -- where three binary axes produce eight vertices that map perfectly to the fundamental tensions in system design.

## The Z2-Cubed Cube

Three axes, each binary, producing 2^3 = 8 vertices:

| Axis | Symbol | 0 | 1 | OS Mapping |
|------|--------|---|---|------------|
| Electromagnetic | epsilon | Dark | Light | Kernel space / User space |
| Gravitational | mu | Massless | Massive | Lightweight processes / Heavyweight services |
| Matter/Antimatter | sigma | Matter | Antimatter | Production / Development-Debug |

### The Eight Vertices

```
        epsilon=1 (User Space)
        /
       /
      +--------+--------+
     /|  V010  /  V110  |        mu=0 (Lightweight)
    / | Light  / Light   |       /
   /  | Mass-  / Mass-   |      /
  +--------+--------+   |
  |  V011  |  V111  |   +      sigma=1 (Antimatter/Dev)
  | Light  | Light   |  /|     /
  | Massive| Massive |/ |    /
  +--------+--------+   |   /
  |  V001  |  V101  |   +--/-----> sigma
  | Dark   | Dark    |  /
  | Massive| Massive |/
  +--------+--------+
     V000  |  V100
     Dark  | Dark
     Mass- | Massless
     less  |
       \
        epsilon=0 (Kernel Space)
```

| Vertex | epsilon | mu | sigma | Name | Role |
|--------|---------|-----|-------|------|------|
| V000 | 0 | 0 | 0 | **Neutrino** | Kernel microthreads, zero-overhead watchers |
| V001 | 0 | 0 | 1 | **Antineutrino** | Kernel debug probes, eBPF tracing |
| V010 | 0 | 1 | 0 | **Neutron** | Core kernel services (scheduler, memory, VFS) |
| V011 | 0 | 1 | 1 | **Antineutron** | Kernel instrumentation, crash dumps, kprobes |
| V100 | 1 | 0 | 0 | **Photon** | Lightweight user daemons, event loops |
| V101 | 1 | 0 | 1 | **Antiphoton** | Dev tools, linters, formatters, watchers |
| V110 | 1 | 1 | 0 | **Electron** | Full user services (databases, web servers) |
| V111 | 1 | 1 | 1 | **Positron** | Debug/test environments, profilers, fuzzers |

## Design Principles

### Alpha Frame
The bootloader and initial kernel are the **Alpha Frame** -- the pre-cubic condition from which all vertices instantiate. Like hydrogen in stellar nucleosynthesis, the Alpha Frame is the simplest possible base. Everything else is built by fusion of hydrogen-primitives.

### Membrane
Boundaries in Waterlight are not rigid walls but **pliable membranes**. Namespace isolation, cgroups, and capabilities are dynamic and adaptive. A process can shift between vertices as its needs change. The membrane stretches, contracts, and breathes.

### Chirality
Every operation has two mirror forms:
- **Right-hand (dextro)**: synthesis, construction, deployment (sigma=0)
- **Left-hand (levo)**: analysis, destruction, debugging (sigma=1)

Switching chirality at any level transforms production infrastructure into development infrastructure and back, without rebuilding.

### Kenosis
The kernel gives itself to become user-space. Resources flow outward from V000 toward V111. The system exists to serve workloads, not to serve itself.

## Technical Choices

| Choice | Selection | Reason |
|--------|-----------|--------|
| Base | Alpine Linux | Hydrogen principle: smallest functional unit |
| libc | musl | Minimal, correct, no historical baggage |
| Core utils | BusyBox | Pre-fusion simplicity |
| Init | Custom (waterlight-init) | Nucleosynthesis-modeled service startup |
| Display | Wayland | Thinner membrane than X11 |
| Filesystem | BTRFS | Copy-on-write = non-destructive chirality |
| Security | Capability-based | Granular, adaptive membranes |
| Containers | Native (podman) | The cube IS containerization |

## Quick Start

```bash
# Build the base image
cd build/
./build.sh

# Or use Docker directly
docker build -t waterlight-os:v0.1 .

# Query vertex state
./scripts/waterlight-vertex.sh status

# Switch chirality (production <-> development)
./scripts/waterlight-chirality.sh toggle

# Manage membranes (namespace isolation)
./scripts/waterlight-membrane.sh create myservice --vertex V100
```

## Repository Structure

```
waterlight-os/
  README.md                    This file
  docs/
    ARCHITECTURE.md            Comprehensive architecture specification
    VERTEX_MAP.md              Eight vertices mapped to OS subsystems
    ALPHA_FRAME.md             Boot/init philosophy and implementation
    MEMBRANE.md                Isolation and boundary model
    PERIODIC_TABLE.md          Service taxonomy via nucleosynthesis
  src/
    alpha-frame/               Bootloader and init system source
    vertex/                    Vertex state management daemon
    membrane/                  Namespace and cgroup tooling
    chirality/                 Mode switching subsystem
  config/
    waterlight/                Default system configuration
  build/
    Dockerfile                 Container-based build
    build.sh                   Build orchestration script
  scripts/
    waterlight-init.sh         Init system entry point
    waterlight-vertex.sh       Vertex state CLI
    waterlight-membrane.sh     Membrane management CLI
    waterlight-chirality.sh    Chirality switching CLI
```

## Version

**v0.1 -- Genesis**

The Alpha Frame breathes. The eight vertices are named. The membranes are defined. The chirality is understood. Now begins nucleosynthesis.

## License

Apache 2.0

## Origin

Waterlight OS emerges from the Waterlight Z2-cubed framework developed by Skinner Layne. The framework maps the symmetry group Z2 x Z2 x Z2 onto fundamental structures -- physical, philosophical, and computational. This operating system is the computational instantiation of that framework.
