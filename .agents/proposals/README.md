# Proposal Development Platform

This directory serves as the collaborative feature roadmap and specification hub between developer and AI assistant. Every proposal idea, enhancement, or architectural proposal is tracked as an individual, version-controlled specification.

## Proposal Board

| ID | Title | Type | Status | Specification |
| :--- | :--- | :--- | :--- | :--- |
| `PSP-001` | Running Containers Display & Granular Podman Inspection | `feature` | `concept` | [psp-001-podman-inspection.md](psp-001-podman-inspection.md) |
| `PSP-002` | Orphaned & Dangling Image Cleanup | `feature` | `concept` | [psp-002-image-prune.md](psp-002-image-prune.md) |
| `PSP-003` | Volume Host Directory Verification & Automatic Creation | `feature` | `concept` | [psp-003-volume-dir-check.md](psp-003-volume-dir-check.md) |
| `PSP-004` | Recipe List Cross-Check (Config vs. Filesystem) | `feature` | `concept` | [psp-004-recipe-list-crosscheck.md](psp-004-recipe-list-crosscheck.md) |
| `PSP-005` | Architectural Evaluation: Centralized Context vs. Parameter Passing | `architecture` | `concept` | [psp-005-central-context-eval.md](psp-005-central-context-eval.md) |
| `PSP-006` | Granular Container Targeting within Pods (`recipe/container`) | `feature` | `concept` | [psp-006-container-targeting.md](psp-006-container-targeting.md) |
| `PSP-007` | Log Aggregation and Tailing (`logs` mode) | `feature` | `concept` | [psp-007-log-aggregation.md](psp-007-log-aggregation.md) |
| `PSP-008` | Health-Aware Lifecycle Ordering | `feature` | `concept` | [psp-008-health-aware-lifecycle.md](psp-008-health-aware-lifecycle.md) |
| `PSP-009` | Environment Variable Management (`.env` Integration) | `feature` | `concept` | [psp-009-env-management.md](psp-009-env-management.md) |
| `PSP-010` | Podman Secrets Integration | `feature` | `concept` | [psp-010-podman-secrets.md](psp-010-podman-secrets.md) |
| `PSP-011` | Pre/Post Execution Hooks | `feature` | `concept` | [psp-011-pre-post-hooks.md](psp-011-pre-post-hooks.md) |
| `PSP-012` | Podman Network & Named Volume Management | `feature` | `planned` | [psp-012-network-volume-management.md](psp-012-network-volume-management.md) |
| `PSP-013` | Systemd / Quadlet Export | `feature` | `concept` | [psp-013-systemd-quadlet-export.md](psp-013-systemd-quadlet-export.md) |
| `PSP-014` | Command Mode Syntax Alignment | `feature` | `concept` | [psp-014-command-syntax-alignment.md](psp-014-command-syntax-alignment.md) |

---

## Status Lifecycle

```text
concept ---> planned ---> in-progress ---> review ---> completed
                                                   \--> rejected
```

* **`concept`:** Initial proposal, motivation, and exploratory approach.
* **`planned`:** Concrete specification, CLI syntax, affected modules, and TDD strategy agreed upon.
* **`in-progress`:** Actively being implemented in `src/pods/` following TDD.
* **`review`:** Code and test suites passing; documentation and changelog entry prepared.
* **`completed`:** Merged, tested in release mode, and released. Retained for historical rationale and traceability.
* **`rejected`:** Decided against, with documented reasoning.

---

## Workflow & Guidelines

Refer to the **`proposal-workflow`** skill in `.agents/skills/proposal-workflow/SKILL.md` for standard procedures on creating, updating, and advancing features.
