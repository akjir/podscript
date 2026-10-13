---
name: update-documentation
description: >-
  Maintain and update README.md and USAGE.md. Activate whenever editing documentation or when CLI modes, actions, options, targeting rules, config/recipe schemas, or system requirements change.
---

# Updating Documentation

## 1. Triggers & Sync Checklist
Update documentation whenever you change:
* **CLI Syntax:** Modes, actions, options, default actions, or target resolution. Sync: `USAGE.md`, `README.md` (`CLI Overview`), CLI help in `src/pods/mode_*.lua`, and `.pods-completion.bash`.
* **Schemas & Behavior:** `config.lua` or recipe fields, defaults, volume/port/naming rules, or config-bypass rules. Sync: `USAGE.md`, `README.md` (if top-level), and root `config.lua` / `recipe.lua`.
* **Requirements:** OS, Lua, or Podman minimum versions. Sync: `README.md` (badges + `Requirements` table) and `AGENTS.md`.

## 2. `README.md` Rules (Onboarding & Overview)
Keep `README.md` concise (~200–250 lines) as the project entry point. Omit a Table of Contents. Maintain this exact section order:
1. **`# PodScript`:** Badges (`Platform`, `Lua`, `Podman`, `License`) + 2-sentence summary (declarative Lua recipes to deterministic Podman CLI commands, zero dependencies).
2. **`## Features`:** Bullet list of core capabilities.
3. **`## Requirements`:** 2-column table (`Component | Minimum Version` — omit implementation notes).
4. **`## Installation`:** Standalone `curl` download, `### CLI Wrapper (Optional)`, and `### Shell Autocompletion (Optional)`. Keep installation and completion setup exclusively in `README.md`.
5. **`## Quick Start`:** Numbered flow (`1.` `pods init`, `2.` `pods create recipe --simulate` + `> [!NOTE]` on `simulate = true` default safeguard, `3.` `create`/`status`/`logs`, `4.` `remove`).
6. **`## Configuration and Recipes`:**
   * `### Configuration (config.lua)`: One complete, valid `config.lua` block showing all keys and `@<group>` nesting.
   * `### Recipes (<name>.lua)`: One complete, valid multi-container recipe (`*db`, `*app`, `publish`, `commands`, `volumes`, `options`) + 3 bullet conventions (`Container Naming`, `Volume Paths`, `Custom Flags`).
7. **`## CLI Overview`:** General syntax block, 4-column summary table (`Mode | Actions | Target | Description`), global options bullet list, and link to `[USAGE.md](USAGE.md)`.
8. **`## Development`:** Single `bash` block with `./task verify`, `./task test [dev|release]`, and `./task build`.
9. **`## License`:** Link to `[LICENSE](LICENSE)` + 1-line warranty disclaimer (no separate `## Disclaimer` section).

## 3. `USAGE.md` Rules (Complete Technical Reference)
Keep `USAGE.md` as the exhaustive technical manual. Omit installation, completion setup, quick-start tutorials, and redundant example appendices. Maintain this exact section order:
1. **`# PodScript Usage Guide`** + **`## Table of Contents`** (2-level nested list matching all `##` and `###` headings, including numbered `#actions-N`, `#options-N`, `#usage-N` anchors).
2. **`## Command Syntax`:** `pods` / `lua pods.lua` syntax, parsing rules (`Mode Resolution`, `No Arguments`, `Option Placement`, `Configuration Bypass`, `Privilege Check`), `### Modes Overview` (4-column table), and `### Global Options` (2-column table).
3. **`## Configuration Reference`:** Schema table (`Key | Type | Default | Required | Description`), `> [!IMPORTANT]` group membership rule, and complete `config.lua` block.
4. **`## Recipe Reference`:**
   * `### Top-Level Fields`, `### Pod Fields`, and `### Container Fields`: Schema tables (`Field | Type | Required | Description`).
   * Subsections: `#### Port Publishing (pod.publish)` (format-to-flag table), `#### Maintenance Commands (pod.commands)` (schema table), `#### Container Naming Rules` (bullets), `#### Volume Mount Rules (container.volumes)` (resolution table), and `### Recipe Example` (complete valid recipe).
5. **`## Targeting Rules`:** Centralized in `### Recipe and Group Targets` (sequential order, first-appearance deduplication, group validation) and `### Container Targets` (index, relative, absolute, and direct container name in `connect`). Do not repeat full targeting rules inside individual mode sections.
6. **Mode Sections (`## <Name> Mode`):** Order modes identically to `Modes Overview`: `Default`, `Logs`, `Connect`, `Command`, `Recipe`, `Config`, `Image`, `Init`. Each mode section must contain:
   * **Intro & Syntax:** 1–2 sentences (state underlying Podman command and if the mode bypasses `config.lua`) + `bash` syntax block.
   * **`### Actions`:** 2-column table (`Action | Description`) sorted alphabetically by action (or `(none)` first for `init`). Include `help` and note default/implicit behavior in parentheses.
   * **`### Options`:** 2-column table (`Option | Description`) sorted alphabetically by flag. List all mode-specific options AND only the global options supported by that mode (e.g., omit `--config=<name>` in `Image Mode`; omit `--simulate` in `Init Mode`).
   * **`### Usage`:** One consolidated `bash` block with `# Comment` lines demonstrating `help`, implicit/default actions, explicit actions, target variations, mode flags, and global flags (`--config=staging --debug ... --simulate`).

## 4. Formatting & Content Standards
* **Tables:** Align all table columns with spaces and `:---` markers. Escape pipes inside cells (`\|`). Keep the 4-column `Modes Overview` table (`Mode | Actions | Target | Description`) and mode order synchronized between `README.md` and `USAGE.md`.
* **No Horizontal Rules:** Never use `---` section dividers; rely on `##`, `###`, and `####` headings.
* **Callouts:** Use GitHub alerts (`> [!NOTE]`, `> [!IMPORTANT]`); never use bold blockquotes (`> **Note:**`).
* **Code & Backticks:** Wrap all CLI modes, actions, flags, file names, field keys, and target patterns in backticks.
* **Schema-Valid Generic Examples:** Every Lua example must pass PodScript validation (include required `name`, `pod.registry`, `containers[i].image`, `recipes.groups`). Use generic placeholders (`example-app`, `db-server`, `cache-server`, `example-stack`, `web-stack`, `app-cli`, `db-cli`, `dbuser`); never use real software names (`nextcloud`, `postgres`, `psql`, `php`, `redis`).
