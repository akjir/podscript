# PodScript AI Assistant Rules

> [!IMPORTANT]
> Update this document upon any architectural or naming changes.

* **Goal:** Lightweight Lua script managing Podman pods/containers via declarative recipes.
* **Core Rules:** Zero external dependencies. Linux only (no Windows/macOS). Modular `src/pods/` and `src/pods-converter/`. NEVER edit `pods.lua` or `pods-converter.lua` directly.
* **Language & Tone:** Always respond and write in English (all code, comments, docs, tests/fixtures, commits). Concise and precise; no emojis.
* **Style:** 4 spaces. English comments/vars. Sort functions alphabetically. Avoid globals. Initialize vars (no `nil`).
* **Reqs:** Lua 5.5+, Podman 5.8.0+. CLI is mode-driven (see [USAGE.md](USAGE.md)).
* **Testing (TDD):** Rigorous testing strictly mandated. Every new feature, logic branch, parser routine, or bug fix for core `pods` and `pods-converter` MUST have comprehensive tests in their respective `tests/` directories.
* **Changelog:** Short, concise entries (6–15 words, past tense, backticks for code, no test changes). See dev skill.
* **Efficiency:** Always optimize for token efficiency; avoid redundant or duplicated information across code, docs, rules, and skills.

## Architecture & Naming
* `header.lua`: `VERSION`, `BUILD`, `get_version_string`
* `log.lua`: `log.*` (including `log.debug_enabled`)
* `system.lua`: `system.*`
* `utilities.lua`: global utility functions
* `utilities_{string,table}.lua`: Extends `string.*` / `table.*`
* `{container,pod,recipe,config}.lua`: Prefixed `<name>__*`. Modular functions are `global function` (localized by `build.lua` for release).
* `main.lua`: Prefixed `main__*`
* `mode_{command,config,default,help,init,recipe,simulate}.lua`: Prefixed `mode_<name>__*`
* **Lua 5.5 & Strict Globals:** `global<const> *` enforced atop every chunk (undeclared globals trigger compile error). Use `table.create` for preallocation, named varargs (`... args`) for variadic functions without manual packing.

## Workflows
* Development & Build: Follow **`podscript-dev-workflow`** skill for `build.lua`, `test.lua`, and dev workflows.
* Release: Follow **`podscript-release`** skill for cutting official releases.
