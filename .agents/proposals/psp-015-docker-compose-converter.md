---
id: PSP-015
title: Docker Compose to PodScript Converter
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-015: Docker Compose to PodScript Converter

## Part 1: Concept & Proposal

### 1.1 Summary
This proposal outlines a framework for translating a `docker-compose.yml` file into a declarative PodScript `recipe.lua`. It details what can be automated, what constitutes an edge case, and where manual intervention is unavoidable due to the structural differences between Docker Compose's service-oriented architecture and PodScript's Podman-native pod model. The functionality will be implemented in a dedicated tool/module called `pods-convert`.

### 1.2 Motivation
Docker Compose is the industry standard for defining multi-container stacks. However, transitioning from Docker to Podman Pods (via PodScript) currently requires manually rewriting the entire specification. Providing an automated scaffolding tool lowers the barrier to entry and allows users to quickly port existing deployments (like Immich, Nextcloud, etc.) into PodScript format.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Parse a `docker-compose.yml` (and `.env` files) into an internal representation.
  * Generate a corresponding `recipe.lua` file mapped to PodScript directives.
  * Build a topological sort for container startup order based on `depends_on`.
  * Deliver this as a standalone `pods-convert` module (a separate artifact from the core `pods` script).
* **Non-Goals:**
  * 100% automated, zero-touch migration. Users will still need to manually handle internal networking quirks (e.g., changing hostnames to `localhost` within a pod) and complex hardware acceleration setups.
  * Advanced Compose features like swarm modes, complex builds, or external network bridging.

### 1.4 Description
* **Command Syntax:**
  ```bash
  pods convert docker-compose.yml [output-recipe.lua]
  # or directly:
  lua pods-convert.lua docker-compose.yml [output-recipe.lua]
  ```
* **Translation Mapping:**
  * `services` -> `containers` array (ordered).
  * `image` -> `registry` and `image`.
  * `ports` (per service) -> `pod.publish` (pod level).
  * `volumes` -> `volumes` array mapping host to container paths.
  * `environment` / `env_file` -> `options` array (`--env` / `--env-file`).
  * `depends_on` -> Used for topological sorting to determine array order.

### 1.5 Alternatives
* Relying entirely on manual translation (creates a high barrier to entry).
* Using `podman-compose` directly (does not take advantage of PodScript's declarative Podman Pod model and centralized `recipe.lua`).

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* **New Tool/Module (`src/pods-convert/`):**
  * A dedicated source directory containing the conversion logic.
  * Compiled via `build.lua` into a standalone `pods-convert.lua` script. This ensures the core `pods` executable remains lightweight, as the converter is an external usecase.
* **Core `pods` Script Integration:**
  * The `convert` CLI mode in `pods.lua` will simply check if `pods-convert.lua` is present alongside it and delegate execution.

### 2.2 Schema & Syntax Changes
* No changes to the core PodScript schema. The converter generates standard `recipe.lua` files.
* Includes generating a `# TODO` comment block at the top of the generated Lua file, warning the user about necessary manual interventions (e.g., replacing service hostnames with `localhost`, setting up `userns` for volumes).

### 2.3 Implementation Details
* **Phase 1: Parsing and Normalization**
  * Load `docker-compose.yml` into a Lua table using a lightweight Lua YAML parser embedded in `src/pods-convert/yaml.lua`.
  * Merge `.env` files if provided.
* **Phase 2: Dependency Resolution**
  * Implement a Directed Acyclic Graph (DAG) sort over `depends_on` to flatten services into an ordered list.
* **Phase 3: Transformation Engine**
  * Map `environment`, `healthcheck`, and `volumes` into `options` flags and native PodScript structures.
  * Resolve named volumes to explicit relative paths with `Z` flags.
* **Phase 4: Code Generation**
  * A Lua string formatter that outputs clean, indented `recipe.lua` code based on the mapped structures.

### 2.4 Testing Strategy
* **Unit Tests (`tests/pods-convert/`):**
  * YAML parsing tests.
  * Topological sorting tests for `depends_on`.
  * Mapping validation (e.g., verifying `ports` are correctly lifted to the pod level).
* **Integration Tests:**
  * Feed a known `docker-compose.yml` (e.g., Immich mockup) into `pods-convert.lua` and assert the output `recipe.lua` structure matches expectations.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Update `build.lua` to compile `src/pods-convert/` into `pods-convert.lua`.
- [ ] Implement YAML parser in `src/pods-convert/`.
- [ ] Implement translation and code generation logic in `src/pods-convert/main.lua`.
- [ ] Implement `pods convert` delegation in `src/pods/mode_convert.lua`.
- [ ] Create test suites in `tests/pods-convert/`.
- [ ] Document in `USAGE.md`.
- [ ] Update `CHANGELOG.md`.
- [ ] Set status to `review`, update `README.md` board, and request manual user review and approval.
- [ ] Manual approval received; set status to `completed`, update `README.md` board, and record delivered artifacts.

### 3.2 Work Log & Decisions
* **2026-09-26:** Concept adapted from `CONVERTER_CONCEPT.md`. Decided to isolate the logic into a standalone `pods-convert.lua` module as per architectural alignment.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
