---
id: PSP-025
title: Deployment History and Rollback Mechanism
status: concept
type: feature
created: 2026-10-09
updated: 2026-10-09
---

# PSP-025: Deployment History and Rollback Mechanism

## Part 1: Concept & Proposal

### 1.1 Summary
Implements a safe update path by preserving the previous container state during updates, allowing for immediate rollbacks in case of failure.

### 1.2 Motivation
A failed `pods update` currently destroys the existing container to create the new one, potentially leaving the system degraded if the new image crashes. Preserving the old container temporarily ensures high availability and rapid recovery.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Keep the old container as a paused or renamed backup during an `update` action.
  * Introduce a `pods rollback` command to quickly restore the previous container state.
* **Non-Goals:**
  * Storing full historical version trees (only the immediate predecessor is kept).

---

*(Further technical design and implementation details to be elaborated later)*
