---
id: PSP-027
title: Declarative File Seeding
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-09
---

# PSP-027: Declarative File Seeding

## Part 1: Concept & Proposal

### 1.1 Summary
Allows copying files or directories from the host into a container during initialization using `podman cp`.

### 1.2 Motivation
Mounting small, static configuration files via host volumes can be overly complex and often creates permission issues. Native file seeding allows injecting config files immediately after container creation, but before the container starts, resolving these friction points.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Introduce a `copy` directive in the recipe schema.
  * Execute `podman cp` automatically between the `create` and `start` lifecycle phases.
* **Non-Goals:**
  * Ongoing synchronization of files after the container has started.

---

*(Further technical design and implementation details to be elaborated later)*
