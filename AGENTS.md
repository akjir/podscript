# PodScript AI Assistant Rules

> [!IMPORTANT]
> Update this file when the architecture or file names change.

* **Goal:** Manage Podman pods and containers with a lightweight Lua script and declarative recipes.
* **Core Rules:** Use zero external dependencies. Support Linux only. Edit modular files in `src/pods/` and `src/pods-converter/`. NEVER edit `pods.lua` or `pods-converter.lua` directly.
* **Version Control:** NEVER commit changes unless the user explicitly instructs you to do so.
* **Language & Tone:** Write all responses, code, comments, documentation, tests, and commits in English. Follow ASD-STE100 (80%). Be concise and precise. Do not use emojis.
* **Style:** Indent with 4 spaces. Remove trailing spaces. Sort functions alphabetically. Avoid globals. Initialize all variables (do not leave them `nil`).
* **Reqs:** Lua 5.5+, Podman 5.8.0+. Use mode-driven CLI syntax (see [USAGE.md](USAGE.md)).
* **Testing (TDD):** Write comprehensive tests in `tests/pods/` or `tests/pods-converter/` for every new feature, logic branch, parser routine, or bug fix.
* **Docs & Templates:** Keep `USAGE.md`, `README.md`, `.pods-completion.bash`, CLI help, and root `config.lua` / `recipe.lua` in sync with code changes per **`update-documentation`**.
* **Changelog:** Follow `podscript-dev-workflow` rules for `CHANGELOG.md`.
* **Efficiency:** Optimize for token efficiency. Avoid redundant information across code, docs, rules, and skills.

## Architecture & Naming
* `header.lua`: `VERSION`, `BUILD`, `get_version_string`
* `log.lua`: `log.*` (includes `log.debug_enabled`)
* `utilities.lua`: `util.*` utility functions
* `utilities_{string,table,system}.lua`: Extends `string.*` or `table.*`, or provides `system.*`
* `{container,pod,recipe,config}.lua`: Prefix `<name>__*`. Declare modular functions as `global function` (`build.lua` localizes them for release).
* `main.lua`: Prefix `main__*`
* `mode_{command,config,connect,default,image,init,logs,recipe}.lua`: Prefix `mode_<name>__*`
* **Lua 5.5 & Strict Globals:** Put `global<const> *` at the top of every chunk. Use `table.create` to preallocate tables. Use named varargs (`... args`) for variadic functions.

## Workflows
* Proposals: Use **`proposal-workflow`** to manage `.agents/proposals/`.
* Development & Build: Use **`podscript-dev-workflow`** to build, test, and develop.
* Documentation: Use **`update-documentation`** to update `USAGE.md`, `README.md`, and completion scripts.
* Security Audit: Use **`red-team-audit`** when triggered by `/red <filename>` or `/red all`.
* Release: Use **`podscript-release`** to create official releases.
