---
id: PSP-028
title: Build System File Insertion Annotation
status: completed
type: enhancement
created: 2026-10-10
updated: 2026-10-10
---

# PSP-028: Build System File Insertion Annotation

## Part 1: Concept & Proposal

### 1.1 Summary
Introduce a new annotation `---@build insert:{"PLACEHOLDER", "FILE_PATH"}` in the PodScript build system. This will allow the build script to directly embed the contents of external files (like templates) into the compiled executable as plain text string literals. Multiple insertions can be stacked and applied sequentially.

### 1.2 Motivation
Currently, if PodScript needs to write a default file (e.g., `config.lua` or an example recipe) to disk, the file contents would have to be hardcoded as a string literal directly within the source code. This makes editing and maintaining those templates difficult. By allowing the build system to embed files, templates can be maintained as normal files in the repository and seamlessly injected into the executable at build time.

### 1.3 Goals & Non-Goals
* **Goals:**
  * Add support for `---@build insert:` annotation in `build.lua`.
  * Support replacing a defined placeholder with the file's plain text contents.
  * Allow stacking multiple `insert` annotations for a single line or block of code.
  * Automatically escape the embedded text as a valid Lua string literal to prevent syntax errors.
* **Non-Goals:**
  * Base64 encoding is excluded for now. We will strictly use plain text escaping.
  * No runtime dependencies for reading files (this happens at build time).

### 1.4 Description
Developers can use the following syntax in any `.lua` file processed by `build.lua`. Multiple annotations can be stacked to replace different placeholders:

```lua
---@build insert:{"TEMPLATE", "src/pods/config.lua"}
---@build insert:{"TEMPLATE2", "src/pods/test.lua"}
local my_config = { a = {"TEMPLATE"}, b = {"TEMPLATE2"} }
```

During `lua build.lua`, the build system will:
1. Detect the `insert` annotations.
2. Read the specified files (`src/pods/config.lua`, `src/pods/test.lua`).
3. Format the contents as safe Lua string literals using `%q`.
4. Replace the literal `{"TEMPLATE"}` and `{"TEMPLATE2"}` placeholders on subsequent lines with the formatted strings.

The resulting compiled `pods.lua` will look like:
```lua
local my_config = { a = "contents of config.lua\n...", b = "contents of test.lua\n..." }
```

### 1.5 Alternatives
* **Multi-line string literals (`[[...]]`):** Maintaining large blocks of text inside Lua source files breaks syntax highlighting and linting for the embedded language.
* **Base64 Encoding:** Considered but rejected for now to keep the implementation simpler and avoid requiring a runtime base64 decoder in Lua.

---

## Part 2: Technical Design & Code Changes

### 2.1 Architecture & Affected Modules
* `build.lua`: Modified to parse the new annotation and manage string replacements.

### 2.2 Schema & Syntax Changes
New annotation format:
`---@build insert:\s*\{\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\}`

### 2.3 Implementation Details
In `build.lua`'s `process_content` function:
1. Maintain an `active_inserts` list/table in the `state`.
2. When an `insert:` line is matched, parse the placeholder and path.
3. Read the file. Use `string.format("%q", content)` to safely format it as a Lua string literal (this also automatically wraps the content in double quotes and escapes newlines).
4. Add to `active_inserts`: `{ placeholder = '{"' .. placeholder .. '"}', replacement = formatted_content }`.
5. For all subsequent code lines, iterate through `active_inserts` and apply `line = line:gsub(placeholder_escaped, replacement_escaped)`. This handles stacked placeholders naturally.

### 2.4 Testing Strategy
* Create a standalone automated test script `tests/test_build.lua`.
* The script should load the `build.lua` chunk, intercept `io.open` for mocked testing, and run end-to-end assertions against `process_content`.
* Test strict early validation (abort on missing file).
* Test correct escaping of magic characters in the inserted text (`%`, `()`, etc.).
* Test stacking multiple placeholders in a single line.

---

## Part 3: Implementation Record & Tasks

### 3.1 Task Breakdown
- [x] Run baseline test suites (`lua test.lua --dev` & `lua test.lua`) to verify clean state.
- [x] Implement `insert` parsing in `build.lua`.
- [x] Build release (`lua build.lua`) and verify string replacement works without breaking syntax.
- [x] Update documentation.
- [x] Set status to `review`, request manual user review.
- [x] Merge and complete.

### 3.2 Work Log & Decisions
* **2026-10-10:** Initial concept drafted. Dropped Base64 requirement to simplify runtime and prioritize stacked plain-text injections.

### 3.3 Delivered Artifacts
* `build.lua`: Implemented `@build insert` annotation.
* `tests/test_build.lua`: Standalone test suite for the build annotation.
