# Concept: Translating Docker Compose to PodScript

## 1. Introduction
This document outlines a conceptual framework for translating a `docker-compose.yml` file into a declarative PodScript `recipe.lua`. Taking the [Immich deployment stack](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml) as a primary case study, we analyze the structural differences between Docker Compose's service-oriented architecture and PodScript's Podman-native pod model. The goal is to provide a comprehensive structural idea for a converter script, detailing what can be automated, what constitutes an edge case, and where manual intervention is unavoidable.

## 2. Analysis of the Immich Docker Compose File
The Immich stack consists of four primary services:
1. **`immich-server`**: The core API and web backend. Relies on Redis and PostgreSQL. Exposes port 2283.
2. **`immich-machine-learning`**: The machine learning worker for image processing. Uses a named volume for model caching.
3. **`redis`**: An ephemeral Valkey/Redis instance for caching and job queuing.
4. **`database`**: A PostgreSQL instance with PGVector for data storage. Requires specific shared memory settings (`shm_size`).

Key Docker Compose features utilized:
- **Environment Variables**: Heavy reliance on `.env` files and inline interpolation (e.g., `${IMMICH_VERSION:-release}`).
- **Dependency Management**: `depends_on` used to control startup order.
- **Volume Mounts**: A mix of bind mounts (using environment variables for paths) and Docker named volumes (`model-cache`).
- **Healthchecks**: Custom commands for Redis and PostgreSQL.
- **Hardware Acceleration**: Commented-out `extends` blocks for GPU passthrough.

## 3. Translation Mapping (Compose -> PodScript)
A direct structural mapping from Docker Compose to PodScript looks like this:

| Docker Compose Feature | PodScript Equivalent | Notes |
| :--- | :--- | :--- |
| `services` | `containers` array | PodScript orders execution sequentially based on array index. |
| `image` | `registry` and `image` | Converter must split strings like `ghcr.io/immich-app/immich-server:latest`. |
| `ports` (per service) | `pod.publish` (pod level) | All ports must be aggregated and exposed at the Pod level, as containers share the network namespace. |
| `volumes` (bind mounts) | `volumes` array | Maps directly: `{ "host", "container", "options" }`. |
| `volumes` (named) | `volumes` array | Translated to relative directory paths within the pod's `path`. |
| `environment` | `options = { "--env KEY='val'" }` | Passed directly to the Podman CLI via `options`. |
| `env_file` | `options = { "--env-file .env" }` | Passed to the CLI. |
| `depends_on` | Array ordering | Converter must topologically sort services and place dependencies first in the `containers` array. |
| `shm_size` | `options = { "--shm-size=..." }` | Passed to the CLI. |

## 4. What Can Be Automated (The "Happy Path")
A robust converter script can successfully automate the following tasks:
- **Container Ordering**: By reading the `depends_on` blocks, the script can construct a Directed Acyclic Graph (DAG) and output the `containers` array in the correct startup order (e.g., `database`, `redis`, `immich-server`, `immich-machine-learning`).
- **Port Aggregation**: Extracting all `ports` from individual services and lifting them to the `pod.publish` block.
- **Image Parsing**: Splitting images into the PodScript `registry` and `image` fields.
- **Basic Configuration**: Translating `container_name` to `name`, `restart` policies, and mapping simple environment variables.

## 5. Challenges and Edge Cases
The paradigm shift from Docker Compose networks to Podman Pods introduces several critical edge cases that a simple 1:1 translation cannot solve natively.

### A. Network Namespace and Service Discovery (The `localhost` Paradigm)
In Docker Compose, services communicate via DNS names matching the service name (e.g., `immich-server` connects to Redis via `redis:6379`). In a Podman Pod, all containers share the same network namespace and communicate via `localhost`.
- **The Issue**: Environment variables defined in `.env` (like `DB_HOSTNAME=database`) will fail in a pod because `database` is not resolvable. It must be changed to `localhost`.
- **Podman Network Quirks**: Because all containers share the pod's network stack, port conflicts can occur if multiple containers internally bind to the same port (e.g., two web services binding to 8080). In Compose, this is fine because they have different IP addresses.
- **Converter Limitation**: The script cannot blindly rewrite environment variables inside a `.env` file, as it doesn't know which variables represent hostnames. It also cannot automatically resolve internal port conflicts within the pod.

### B. Environment Variable Interpolation
Compose supports shell-like interpolation: `${IMMICH_VERSION:-release}`.
- **The Issue**: PodScript is written in Lua. While Podman can handle some interpolation if passed via `--env-file`, inline variables in the Compose file need to be parsed.
- **Solution**: The script could generate Lua code to resolve this: `image = "immich-server:" .. (os.getenv("IMMICH_VERSION") or "release")`. However, this requires a sophisticated code generator. A simpler fallback is passing them raw and letting Podman/Bash resolve them, or requiring a `.env` file strictly.
- **Environment Variable Precedence**: The converter must accurately reflect Docker Compose's strict precedence rules (e.g., shell environment overrides `.env` files, which override `environment` blocks). This precedence must be translated into the precise order of `--env` and `--env-file` flags in the `options` array.

### C. Volume Management (Named vs. Bind)
Docker abstracts named volumes (e.g., `model-cache:/cache`). PodScript prefers explicit relative or absolute paths.
- **Solution**: The converter can map named volumes to relative directories within the pod (e.g., `{ "model-cache", "/cache", "Z" }`), which PodScript resolves dynamically.
- **Volume Ownership & User Namespaces**: Rootless Podman introduces UID/GID shifting via user namespaces (`userns`). Bind mounts might have permission issues inside the container because the host user ID doesn't match the container's internal user ID. A converter should consider adding `--userns=keep-id` to the `options` array or flag these volumes for manual `podman unshare chown` commands in a generated `# TODO` block.

### D. Advanced Compose Features
- **Extends/Include**: Resolving `extends` requires the converter to merge multiple YAML files before translation.
- **Healthchecks**: Translating the nested `healthcheck` dictionary into flat Podman flags (`--health-cmd`, `--health-interval`, `--health-retries`, `--health-start-period`, `--health-timeout`) is required. In PodScript, these are appended to the container's `options` array.

## 6. Required Manual Interventions
Even with an advanced converter, the user will have to perform manual post-translation steps:
1. **Network Configuration Adjustment**: Modifying the `.env` file so that database and Redis hostnames point to `localhost` or `127.0.0.1` instead of their Compose service names.
2. **Hardware Acceleration Setup**: Translating GPU bindings (e.g., `/dev/dri`) into PodScript `options = { "--device /dev/dri" }`, as these are often commented out or abstracted in the source Compose file.
3. **Directory Provisioning**: Ensuring that relative volume paths (like `./model-cache`) exist and have the correct SELinux contexts (though PodScript handles `Z` flags, the host user mapping might require `podman unshare chown`).

## 7. Structural Design of the Converter Script
To maintain zero external dependencies and keep the ecosystem unified, the converter will be implemented in **Lua**, sharing utilities and paradigms with the main PodScript core. 

### A. Repository Architecture
The repository has been split into logical components:
- `src/pods/`: Contains the main PodScript logic (to be compiled into `pods.lua`).
- `src/pods-converter/`: Contains the conversion logic (to be compiled into `pods-converter.lua`).
- `tests/pods/` & `tests/pods-converter/`: Segregated test suites.
The build system (`build.lua`) has been updated to produce both standalone artifacts.

### B. Execution Flow (`pods convert`)
The `pods convert` command will be a mode within the core `pods.lua` script. When invoked:
1. It checks if `pods-converter.lua` exists in the same directory as the executing `pods.lua`.
2. If found, it delegates the conversion process to this file.
3. If missing, it aborts with an error indicating that the converter module is required but not installed.

### C. Translation Phases
The architecture of `pods-converter.lua` will consist of four phases:

#### Phase 1: Parsing and Normalization
- Load `docker-compose.yml` into a Lua table structure (requires a lightweight Lua YAML parser integrated into the converter).
- Merge any `.env` files provided as arguments to resolve interpolations in memory.

#### Phase 2: Dependency Resolution (Topological Sort)
- Build a graph of services based on `depends_on`.
- Sort the graph to produce a flat list of services. This dictates the order of the `containers` array in Lua.

#### Phase 3: Transformation Engine
- **Pod Builder**: Iterate over all services to extract `ports` and global settings.
- **Container Builder**: For each sorted service, map its properties to a PodScript Lua table representation.
  - Map `environment` dictionaries to `--env` strings.
  - Process `healthcheck` blocks into `--health-*` strings.

#### Phase 4: Code Generation
- Implement a Lua template renderer that takes the internal data structures and formats them into a clean, well-commented `recipe.lua` file.
- Append a generated `# TODO` comment block at the top of the Lua file, warning the user about the `localhost` network paradigm and variables requiring manual attention.

## 8. Conclusion
A Docker Compose to PodScript converter is highly feasible but must be treated as a *scaffolding tool* rather than a magical one-click migrator. The structural differences between isolated container networks and unified Pod namespaces mean the converter can do 90% of the heavy lifting (syntax mapping, dependency ordering), leaving the final 10% (network configuration, volume permissions via user namespaces, and hardware tuning) to the developer.
