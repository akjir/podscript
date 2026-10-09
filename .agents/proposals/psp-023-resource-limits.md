---
id: PSP-023
title: Resource Limits and Hardware Quotas
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-09
---

# PSP-023: Resource Limits and Hardware Quotas

## Part 1: Concept & Proposal

### 1.1 Summary
Introduces declarative schema properties to restrict hardware resource usage (CPU, memory, PIDs, devices) for containers.

### 1.2 Motivation
Preventing containers from exhausting host resources is critical in production environments to avoid host OOM conditions or CPU starvation. PodScript currently lacks native schema mapping for these essential Podman constraint flags.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Map core Podman resource flags (`--memory`, `--cpus`, `--pids-limit`, `--device`) into the recipe container schema.
  * Pass these limits correctly during the `podman create` execution phase.
* **Non-Goals:**
  * Real-time resource monitoring or dynamic quota adjustment.

---

*(Further technical design and implementation details to be elaborated later)*
