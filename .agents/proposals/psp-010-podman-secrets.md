---
id: PSP-010
title: Podman Secrets Integration
status: concept
type: feature
created: 2026-09-26
updated: 2026-09-26
---

# PSP-010: Podman Secrets Integration

## 1. Summary & Motivation
Currently, PodScript lacks a native declarative mechanism to manage sensitive data like passwords, API keys, and certificates. Users are forced to rely on environment variables or manual host-mounted files, which poses security risks. Integrating Podman's native secret management (`podman secret`) will allow users to define secrets safely in their recipes and inject them into containers as mounts or environment variables, adhering to security best practices.

## 2. Goals & Non-Goals
* **Goals:**
  * Add a `secrets` block to the root of the recipe schema to define secrets backed by local files.
  * Allow containers to reference these secrets via a `secrets` array in the container definition (supporting both shorthand string syntax and detailed table configurations).
  * Automatically create defined secrets during `pods create` / `pods recreate` (using `podman secret create --ignore` or similar logic).
  * Properly append the `--secret` flag to the `podman run` command when creating containers.
* **Non-Goals:**
  * No support for creating secrets from standard input (stdin) via the CLI. Secrets must be backed by files to maintain the declarative, reproducible nature of recipes.
  * No automatic rotation or updating of secrets for running containers without recreating them.
  * No external secret manager integration (e.g., HashiCorp Vault) – relies solely on Podman's local secret store.

## 3. Specification & CLI Syntax
* **CLI Syntax:** No new CLI commands are introduced. The existing `pods create`, `pods remove`, `pods recreate`, and `pods update` actions will handle secrets automatically during the lifecycle.
* **Recipe Schema Additions:**
  * **Root `secrets` array:** Defines the secrets to be created on the host.
    ```lua
    secrets = {
        {
            name = "db_password",
            source = "./secrets/db_password.txt", -- Path relative to recipe file or absolute
            labels = { "env=production" }         -- Optional metadata
        },
    }
    ```
  * **Container `secrets` array:** Injects existing secrets into the container.
    ```lua
    containers = {
        {
            name = "*db",
            image = "postgres:15",
            secrets = {
                "db_password", -- Shorthand (mounts to /run/secrets/db_password)
                {
                    source = "api_key",
                    type = "env",
                    target = "API_KEY"
                },
                {
                    source = "cert",
                    type = "mount",
                    target = "/etc/ssl/cert.pem",
                    uid = 1000,
                    gid = 1000,
                    mode = 400
                }
            }
        }
    }
    ```

* **Execution Behavior:**
  * **Create:** For each secret in the root `secrets` array, PodScript will run `podman secret create --ignore <name> <source>`.
  * **Run:** Appends `--secret <options>` to the `podman run` command. Table-based configurations are joined by commas (e.g., `--secret source=api_key,type=env,target=API_KEY`).
  * **Remove:** Optionally remove secrets? Since secrets may be shared, PodScript will run `podman secret rm --ignore <name>` during `pods remove` for secrets explicitly defined in the recipe.

## 4. Technical Architecture
* **Affected Files:**
  * `src/pods-converter/recipe.lua`: Extend parsing and validation to support the root `secrets` array and container-level `secrets`.
  * `src/pods/container.lua`: Modify the `podman run` command generation to append `--secret` arguments.
  * `src/pods/pod.lua`: Inject secret creation steps (`podman secret create --ignore`) before starting containers, and removal steps (`podman secret rm --ignore`) during teardown.
* **Strict Lua 5.5 rules:** Ensure all new functions declare `global<const> *` and use `table.create` for constructing the `--secret` arguments efficiently without unnecessary memory reallocation.
* **Path Resolution:** The `source` file path in the root `secrets` block must be resolved relative to the recipe file's directory (similar to how volume paths might be resolved) or absolute.

## 5. Test Strategy (TDD)
* **`tests/pods-converter/recipe_test.lua`:**
  * Validate correct parsing of the `secrets` root block.
  * Validate container `secrets` parsing (both shorthand string and detailed table formats).
  * Assert validation errors for missing required fields (e.g., missing `source` or `name`).
* **`tests/pods/container_test.lua`:**
  * Verify that `--secret` flags are generated correctly and appended to the `podman run` command array.
  * Test edge cases for `type=env` and `type=mount` with permissions (`uid`, `gid`, `mode`).
* **`tests/pods/pod_test.lua`:**
  * Verify `podman secret create` is executed before container startup in `create` actions.
  * Verify `podman secret rm` is executed during `remove` actions.
* **Simulation Tests:** Ensure `pods simulate create` outputs the exact `podman secret` commands and correct `podman run --secret` flags.

## 6. Work Log & Decisions
* **2026-09-26:** Initial concept and specification created. Decided to support both string shorthands and verbose tables for container secrets to match Podman's flexibility while keeping simple use-cases clean. Chose to use `--ignore` for idempotent secret creation, requiring Podman 5.8.0+.
