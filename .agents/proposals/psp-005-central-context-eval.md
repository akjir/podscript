---
id: PSP-005
title: Architectural Refactoring: Explicit Context Table
status: ready
type: architecture
created: 2026-09-25
updated: 2026-09-26
---

# PSP-005: Architectural Refactoring: Explicit Context Table

## Part 1: Concept & Proposal

### 1.1 Summary
The `registry` table is refactored into a formally structured `context` table. Instead of a centralized singleton module (`context.lua`), we will continue to pass this context explicitly across mode handlers, config loaders, and validators. This guarantees 100% test isolation, as every script invocation (e.g., `main()`) creates its own independent `context` instance. The goal is to clearly define the schema of the `context` table and specify what information is contained and required by each mode.

### 1.2 Motivation
The current `registry` table lacks a strict definition of its properties and usage across different modes. Renaming it to `context` and standardizing its schema clarifies the data flow and architectural intent without the drawbacks of global mutable state. A well-defined `context` makes function signatures predictable and unit testing straightforward.

### 1.3 Goals & Non-Goals
* **Goals:**
    * Replace `registry` with a clearly defined `context` table.
    * Maintain explicit parameter passing of the `context` object to preserve test isolation.
    * Document exactly what information the `context` table holds and provides in each mode.
* **Non-Goals:**
    * Introducing a singleton `context.lua` module (this alternative has been evaluated and rejected).
    * Modifying the core recipe syntax or pod generation logic.

### 1.4 Description
A `context` table is instantiated directly at the start of `main()`. It replaces the current `registry` and acts as the single source of truth passed through the application's lifecycle for a specific run.

#### Context Schema & State Mutability
To enforce a clear data flow, the fields inside the `context` table are explicitly categorized as either Read-Only (RO) after initialization or Mutable:

```lua
local context = {
    -- MUTABLE: Populated and mutated by config.lua loaders
    config = {
        name = "config", -- The provided config name
        path = "",       -- The resolved full path to the config file
        simulate = true, -- Default simulate value
        editor = "",     -- Default editor
        pods = { path = "" },
        recipes = { path = ".", groups = {} },
    },
    
    -- READ-ONLY (RO): Parsed once from CLI
    flags = {},          -- Parsed command-line flags (e.g., { ["--debug"] = true })
    parameters = {},     -- Parsed positional command-line arguments
    
    -- READ-ONLY (RO) after main.lua initialization
    mode = {
        selected = modes.default, -- The selected mode handler function
    },
    
    -- READ-ONLY (RO): Parsed centrally in main.lua after config load
    action = "",         -- The single action to execute
    targets = {},        -- The untangled list of targets
}
```

#### CLI Schema & Centralized Action Parsing
* **Global Call Schema:** All modes and external modules must strictly follow the schema: `pods MODE ACTION TARGETS`.
* **Single Action Rule:** There is strictly **only one action** permitted per invocation of PodScript.
* By centralizing the CLI schema, we can extract the target untangling logic. Instead of each mode untangling its own targets, `main.lua` will invoke `parse_action_and_targets_parameters` (or equivalent) after the configuration is loaded, populate `context.action` and `context.targets`, and then pass the fully prepared context to the modes.#### Mode Context Requirements
Each mode handler receives the `context` table and utilizes specific information from it:

* **mode_command**: 
  * *Constraint regarding PSP-014:* From the outside (e.g., in `main.lua`), we treat `mode_command` exactly as if it has already been fully converted to the new central schema (`pods MODE ACTION TARGETS`). During implementation, we will ensure that `mode_command__handle` and its subsequent internal functions continue to work correctly with the new `context` object (using shim or mapping logic if necessary). However, the deep, true architectural optimization and syntax alignment for this mode remains strictly within the scope of **PSP-014**.
* **mode_config**:
  * `config`: Needed to output and display the currently loaded configuration.
  * `config.path`: Needed to display the path of the file being read.
* **mode_default**:
  * `config`: Contains the default recipes and pods to execute when no explicit mode is provided.
* **mode_help**:
  * Requires minimal context, but may use `flags` to determine if a specific help topic was requested.
* **mode_init**:
  * `config.path`: Used as the target destination to generate and write the default configuration file. (Does not require `config` as it creates it).
* **mode_recipe**:
  * `config`: Contains the defined recipes.
  * `parameters`: Specifies the name of the recipe the user wants to run.
  * `flags`: Used for potential recipe-level overrides.
* **mode_simulate**:
  * `config`: Contains the configuration to dry-run and print without execution.

### 1.5 Context Scope & Boundaries
To prevent the centralized `context` from creating tight coupling with the core domain logic, a strict boundary must be enforced:
* **Mode Controllers (`mode_*.lua`)**: ✅ **CAN** pass and use the full `context` object freely across their own internal helper functions (e.g., `mode_recipe__edit(context, name)`). This acts as the controller layer and keeps internal signatures clean without parameter explosion.
* **Generators, Converters & External Modules (e.g., `src/pods-converter/`)**: ✅ **CAN** receive the full `context` object. Because the context now natively bundles `flags` and `parameters`, passing just the `context` is entirely sufficient to hand off full execution to these external/generation tasks without massive function signatures.
* **Core Domain (`pod.lua`, `container.lua`, `recipe.lua`)**: ❌ **MUST NOT** receive the `context` object. They must remain pure and decoupled. When a mode function calls a domain function, it must unwrap the `context` and pass only the specific required data (e.g., `pod__generate(context.config.pods["my-pod"])`, not `pod__generate(context, "my-pod")`).

### 1.6 Alternatives
* **Singleton `context.lua`**: Initially proposed but rejected. A singleton introduces a high risk of state leakage in the test runner, since `test.lua` runs multiple tests sequentially in a single Lua process. Strict state isolation is prioritized.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `src/pods/main.lua`: Replace the instantiation of `registry` with `context`.
* `src/pods/mode_*.lua`: Update function signatures to accept `context` instead of `registry` and adjust internal variable references.
* `src/pods/config.lua`: Update config loaders to populate `context.config`.

### 2.2 Schema & Syntax Changes
No user-facing syntax or schema changes. Internal variables named `registry` become `context`.

### 2.3 Implementation Details
* **Global Rules Meta-Constraint:** During the execution of this proposal, the rules and constraints defined herein must be strictly adhered to. For all aspects not explicitly modified by this PSP, the overarching rules defined in `AGENTS.md` and the existing PodScript development skills apply implicitly.
* Rename `registry` to `context` globally.
* Pass `context` explicitly as the first parameter to mode handlers and config functions.
* Bundle redundant arguments into the `context` object where possible. For example, `config__load_and_set(registry, config_full_path)` simplifies to `config__load_and_set(context)` since the path is already contained within `context.config.path`.
* Ensure sufficient inline documentation (LuaDoc `---@param context table`) and inline comments are added/updated to explain the context usage and intent within functions.
* Enforce strict adherence to the defined schema; do not dynamically attach ad-hoc fields to `context` deep within the application.

### 2.4 Testing Strategy
* **Zero Test Modification Rule:** No tests may be altered during this refactoring. The tests must pass exactly as they do currently.
* Because the testing framework primarily drives the application via CLI arguments and configuration files (end-to-end), renaming internal variables (`registry` to `context`) must have zero impact on the test suite execution.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [ ] Refactor `main.lua`: Merge `startup_config` into the new `context` table and replace `registry` initialization.
- [ ] Update `main__parse_arguments` to operate directly on the unified `context` object.
- [ ] Implement `parse_action_and_targets_parameters` (or similar) in `main.lua` to populate `context.action` and untangled `context.targets` globally after config load.
- [ ] Update function signatures across all `mode_*.lua` handlers. (For `mode_command`, perform a shallow update only).
- [ ] Optimize internal logic of modes (except `mode_command`) to utilize `context.action` and `context.targets` directly.
- [ ] Update `config.lua` functions to accept and mutate `context`.
- [ ] Verify that all existing tests pass without any modifications to the `tests/` directory.

### 3.2 Work Log & Decisions
* **2026-09-25:** Initial architectural analysis conducted on centralized contexts.
* **2026-09-26:** Direction finalized: Rejected singleton `context.lua` to guarantee test runner isolation. Decided to maintain explicit parameter passing but formalize the previous ad-hoc `registry` into a strictly defined `context` table, detailing mode-specific dependencies.

### 3.3 Delivered Artifacts
*(Filled out upon completion)*
