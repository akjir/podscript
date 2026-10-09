---
id: PSP-022
title: Native Container Image Building
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-09
---

# PSP-022: Native Container Image Building

## Part 1: Concept & Proposal

### 1.1 Summary
This feature introduces native support for building container images directly within PodScript via a `build` block in the recipe.

### 1.2 Motivation
Currently, recipes require pre-built images to be available locally or in a remote registry. By delegating image builds to `podman build` directly from the recipe, users can seamlessly orchestrate custom images and iterative development workflows without manual pre-flight build steps.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Add a declarative `build` block to the recipe schema.
  * Integrate `podman build` execution prior to the `create` phase if the image is missing or a rebuild is forced.
* **Non-Goals:**
  * Replacing complex CI/CD pipelines or multi-stage build orchestration tools.

---

*(Further technical design and implementation details to be elaborated later)*
