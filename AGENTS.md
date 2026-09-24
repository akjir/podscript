# PodScript AI Assistant Rules

> [!IMPORTANT]
> Update this document upon any architectural or naming changes.

* **Goal:** Lightweight Lua script managing Podman pods/containers via declarative recipes.
* **Core Rules:** Zero external dependencies. Modular `src/`. NEVER edit `pods.lua` directly.
* **Language & Tone:** Always communicate and respond in English, regardless of input language. All code, comments, documentation, and git commits must be exclusively in English. Keep language concise and precise; never use emojis.
* **Style:** 4 spaces. English comments/vars. Sort functions alphabetically. Avoid globals (`global<const> *` enforced). Initialize vars (no `nil`).
* **Reqs:** Lua 5.5+, Linux, Podman 5.8.0+.
* **CLI:** Mode-driven. See [USAGE.md](USAGE.md).
* **Changelog:** Short, concise entries (6–15 words, past tense e.g. `Added ...`, `Changed ...`, backticks for code). Do not include test additions or changes. See dev skill.

## Architecture & Naming
* `header.lua`: `global<const> *`, `VERSION` / `log.lua`: `log.*` (including `log.debug_enabled`) / `system.lua`: `system.*` / `utilities.lua`: global utility functions.
* `utilities_{string,table}.lua`: Extends `string.*` / `table.*`.
* `{container,pod,recipe,config}.lua`: Prefixed `container__*`, `pod__*`, `recipe__*`, `config__*`. In `src/`, modular functions are defined as `global function` (localized by `build.lua` for release).
* `main.lua`: Prefixed `main__*`.
* `mode_{default,simulate,config,recipe,command,help}.lua`: Prefixed `mode_<name>__*`.
* Strict Globals: `global<const> *` is enforced at the top of every chunk; any accidental undeclared global causes a compile error.
* Lua 5.5 Features: `global<const> *` for strict globals, `table.create` for table preallocation, and named varargs (`... args`) for variadic functions without manual packing.

## Workflows (Building & Testing)
For the build system (`build.lua`), testing framework (`test.lua`), and the development workflow, the agent should activate and follow the **`podscript-dev-workflow`** skill.
