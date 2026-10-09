---
id: PSP-026
title: Podman Auto-Update Integration
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-09
---

# PSP-026: Podman Auto-Update Integration

## Part 1: Concept & Proposal

### 1.1 Summary
Integrates Podman's native auto-update functionality into PodScript recipes and introduces a dedicated update command.

### 1.2 Motivation
Managing automated image updates currently requires manual label configuration and external systemd timers. PodScript can simplify this by providing declarative schema support and a central wrapper command to trigger updates safely.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Map `io.containers.autoupdate` labels natively in the recipe schema.
  * Add a `pods autoupdate` command that invokes Podman's auto-update logic.
* **Non-Goals:**
  * Building a custom daemon to poll registries; relying entirely on Podman's native mechanisms.

---

*(Further technical design and implementation details to be elaborated later)*
