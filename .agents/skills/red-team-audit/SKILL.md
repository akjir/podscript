---
name: red-team-audit
description: >-
  Acts as an adversarial Red Team Security Auditor to break, exploit, and harden PodScript. Triggered when the user types `/red <filename>` or `/red all`.
---

# Red Team Audit & Hardening Workflow

Run this workflow when the user invokes `/red <filename>` or `/red all`. Adopt the persona of an adversarial attacker combined with a strict security engineer.

## 1. Adversarial Reconnaissance (Red Team Phase)
Assume the target code is flawed and vulnerable. Evaluate `src/pods/` and `src/pods-converter/` against these failure scenarios:
1. **Command Injection & Destructive Execution:** Can unescaped CLI arguments, config/recipe fields (`name`, `image`, `registry`, `publish`, `volumes`, `options`, `commands`, `editor`), shell metacharacters, newlines, or leading dashes (`-`) bypass `string.escape_shell` or `simulate` mode to execute arbitrary commands or destructive `podman` operations via `system.exec`, `system.exec_capture`, `os.execute`, or `io.popen`?
2. **Path Traversal & Arbitrary File Access:** Can malformed paths (`..`, `\0`, leading `-`, symlinks, or relative/absolute path collisions) in `--config`, `pods.path`, `recipes.path`, `container.volumes`, or `mode_init` bypass `util.build_full_path` or `system.get_absolute_path` to read, overwrite, or mount sensitive host files outside the target directory?
3. **Unsafe Lua Execution & Privilege Escalation:** Can malformed or untrusted Lua files loaded via `system.load_lua_file` (`loadfile` / `pcall`) corrupt the global environment (`_G`), bypass `system.runs_elevated()` root checks, or leak sensitive host data into logs or stdout?
4. **State Corruption, Safeguard Bypass & Resource Exhaustion:** Can cyclic group references in `config__untangle`, unexpected `podman` output, nil/type confusion, or unbounded inputs corrupt `context` state, bypass `simulate = true` safeguards, or cause infinite loops / hangs?

## 2. Exploitation Report & Decision Gate (Anti-Hallucination)
* **If the Code is Secure:** If the file defends against all vectors (strict type checks, shell escaping, path validation, and error handling), declare the file **"SECURE"**. Do **NOT** invent bugs or refactor for style. Stop the workflow immediately.
* **If Vulnerabilities are Found:** List the exact attack vectors concisely. Explain how an attacker or edge case triggers the failure. Provide file names and line numbers. Wait for explicit user approval before modifying any code.

## 3. Remediation (Blue Team Phase - TDD)
After the user approves the report, harden the code per **`podscript-dev-workflow`** without breaking existing functionality:
1. **Write Exploit Tests First:** Add tests in `tests/pods/suite_*.lua` or `tests/pods-converter/suite_*.lua` that simulate the identified attacks (e.g., shell metacharacters, `..` path traversal, cyclic groups, flag injection, or `simulate` bypass).
2. **Harden the Source Code:** Refactor the target file in `src/pods/` or `src/pods-converter/` (never edit `pods.lua` or `pods-converter.lua` directly) to block the attacks. Enforce strict type bounds, `string.escape_shell`, early returns, and explicit errors.
3. **Closed-Loop Verification:** Run `./task verify`. If any dev test, build step, or release test fails, fix the root cause and re-run `./task verify` until all checks pass.

## 4. Finalization
Report the mitigation and verification results. Do not run `git commit` unless explicitly instructed.
