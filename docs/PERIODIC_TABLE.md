# The Periodic Table of System Services

## Nucleosynthesis Model

Just as chemical elements are built from protons, neutrons, and electrons through nuclear fusion, system services are built from hydrogen primitives through software composition. The element number of a service is the count of hydrogen primitives it fuses together.

## Hydrogen Primitives

The eight irreducible building blocks of all services:

| # | Primitive | Symbol | Description |
|---|-----------|--------|-------------|
| 1 | h-socket | Sk | A listening network socket (TCP, UDP, Unix) |
| 2 | h-timer | Tm | A periodic or one-shot timer trigger |
| 3 | h-watch | Wt | A filesystem or event watcher (inotify, epoll) |
| 4 | h-pipe | Pp | A data transformation/forwarding stage |
| 5 | h-store | St | A stateful storage component (memory, disk) |
| 6 | h-gate | Gt | An access control or validation checkpoint |
| 7 | h-log | Lg | A structured log emitter |
| 8 | h-signal | Sg | An inter-process communication primitive |

## Fusion Notation

A service definition uses fusion notation:

```
<service-name> = <primitive>(<params>) + <primitive>(<params>) + ...
vertex: V<nnn>
element: <number> (<name>)
```

## The Periodic Table

### Period 1: Hydrogen and Helium (Elements 1-2)

Services composed of 1-2 primitives. The simplest possible services.

| Element | Name | Composition | Vertex | Description |
|---------|------|-------------|--------|-------------|
| 1 | **Hydrogen** | `h-log` | V100 | Pure log emitter (heartbeat, watchdog) |
| 2 | **Helium** | `h-timer + h-signal` | V100 | Cron-like periodic signal sender |

### Period 2: Lithium through Neon (Elements 3-10)

Lightweight services. These populate V100 (Photon) and form the connective tissue of the system.

| Element | Name | Composition | Vertex | Description |
|---------|------|-------------|--------|-------------|
| 3 | **Lithium** | `Sk + St + Lg` | V100 | DNS cache/forwarder |
| 4 | **Beryllium** | `Sk + Pp + Gt + Lg` | V100 | TCP proxy with auth |
| 5 | **Boron** | `Tm + Wt + Pp + St + Lg` | V100 | Config sync daemon |
| 6 | **Carbon** | `Sk + Tm + Pp + St + Gt + Lg` | V100 | HTTP health checker |
| 7 | **Nitrogen** | `Sk + Tm + Wt + Pp + St + Gt + Lg` | V100 | Certificate manager |
| 8 | **Oxygen** | `Sk(2) + Pp + St + Gt(2) + Lg + Tm` | V110 | Web server (simple) |
| 9 | **Fluorine** | `Sk + Tm + Wt + Pp(2) + St + Gt + Lg + Sg` | V100 | Log aggregator |
| 10 | **Neon** | `Sk + St(2) + Gt(2) + Lg + Tm + Pp + Wt + Sg` | V110 | Simple database |

### Period 3: Sodium through Argon (Elements 11-18)

Medium-weight services. Transition from V100 to V110 territory.

| Element | Name | Composition | Vertex | Description |
|---------|------|-------------|--------|-------------|
| 11 | **Sodium** | Neon + `Sk` (replication) | V110 | Database with replication |
| 12 | **Magnesium** | `Sk(2) + Pp(3) + St(2) + Gt(2) + Lg + Tm + Sg` | V110 | Message broker |
| 14 | **Silicon** | Complex composition | V110 | Container runtime |
| 16 | **Sulfur** | Complex composition | V110 | CI/CD runner |
| 18 | **Argon** | Complex composition | V110 | Monitoring stack |

### Period 4: Potassium through Iron (Elements 19-26)

Heavyweight services. These are the most complex services that the system will auto-start.

| Element | Name | Composition | Vertex | Description |
|---------|------|-------------|--------|-------------|
| 19 | **Potassium** | Complex composition | V110 | Full web application |
| 22 | **Titanium** | Complex composition | V110 | Distributed database |
| 24 | **Chromium** | Complex composition | V110 | Kubernetes-like orchestrator |
| 26 | **Iron** | Complex composition | V110 | Full platform stack |

### The Iron Ceiling (Element 26)

**No service with element number > 26 is automatically started at boot.**

Iron is the heaviest element producible by stellar fusion. Heavier elements require supernova conditions -- external energy injection. In Waterlight OS, services heavier than iron require explicit operator action to start.

This is not an arbitrary limit. It reflects the principle that a system should boot to a known, stable, bounded state. Unbounded automatic startup is the path to systemd -- a system so fused it cannot be decomposed.

### Post-Iron Elements (27+)

These services exist but require manual instantiation:

| Range | Description | Example |
|-------|-------------|---------|
| 27-54 | Heavy application stacks | ERP systems, ML training pipelines |
| 55-86 | Multi-service architectures | Microservice meshes, data lakes |
| 87+ | Radioactive (unstable) | Experimental, research, prototype systems |

"Radioactive" services are those that are inherently unstable -- they may crash, leak, or behave unpredictably. They belong exclusively in V111 (Positron) and should never be promoted to production without decaying into a stable isotope (refactored to lower element number).

## Fusion File Format

Services are defined in `.fusion` files:

```ini
# /etc/waterlight/fusion/dns-resolver.fusion

[identity]
name = dns-resolver
element = 3
element_name = Lithium
vertex = V100
description = DNS caching resolver and forwarder

[composition]
# List hydrogen primitives with parameters
h-socket = udp:53, tcp:53
h-store = memory:cache:64M:ttl
h-log = structured:json:/var/waterlight/log/dns.log

[membrane]
profile = photon
memory_high = 32M
memory_max = 64M
cpu_weight = 50
capabilities = cap_net_bind_service

[lifecycle]
start_phase = carbon    # Phase 3
depends_on = networkd
restart = on-failure
restart_delay = 5s
health_check = dns:localhost:53:A:localhost

[chirality]
# sigma=1 additions
antimatter_extras = h-log(debug:verbose), h-pipe(stats:prometheus:9153)
antimatter_caps = +cap_sys_ptrace
```

## Isotopes

A service can have isotopes -- variants with the same element number but different internal composition. For example:

```
# dns-resolver isotope: unbound
dns-resolver/unbound = h-socket(udp:53,tcp:53) + h-store(memory:64M) + h-log
vertex: V100, element: 3

# dns-resolver isotope: dnsmasq
dns-resolver/dnsmasq = h-socket(udp:53,tcp:53) + h-store(memory:32M) + h-log
vertex: V100, element: 3

# dns-resolver isotope: coredns
dns-resolver/coredns = h-socket(udp:53,tcp:53) + h-store(memory:128M) + h-log
vertex: V100, element: 3
```

Same function, same element number, different implementation. The system does not care which isotope is running -- the membrane profile and vertex classification are identical.

## Decay and Fission

### Decay

A service can decay to a lower element number by shedding primitives:

```
# Full web server (Oxygen, element 8)
web-server = Sk(2) + Pp + St + Gt(2) + Lg + Tm

# Decays to static file server (Carbon, element 6) by dropping Gt(auth) and St(session)
static-server = Sk(2) + Pp + Gt(tls) + Lg + Tm
```

### Fission

A service can split into two lighter services:

```
# Monolith app server (Iron, element 26)
# Fissions into:
api-server (Neon, element 10) + worker (Neon, element 10) + gateway (Carbon, element 6)
```

Fission is the mechanism by which monoliths decompose into microservices. Waterlight encourages fission for any service above Argon (element 18).
