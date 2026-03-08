# PodScript Development Guidelines for AI Assistants

This document provides instructions for developing and maintaining the PodScript project. Please adhere to these guidelines strictly.

## 1. Project Overview

PodScript is a lightweight Lua script for managing Podman pods and containers. It uses declarative Lua files (called "recipes") to define pod configurations.

**Core Principles:**
*   **Simplicity:** The project aims for simplicity and has no external dependencies.
*   **Declarative:** Pods and containers are defined in Lua recipe files.
*   **Single File Logic:** The core application logic is self-contained in `pods.lua`.

## 2. Technical Specifications

*   **Language:** Lua 5.4
*   **Dependencies:** None. Do not add any external dependencies.

## 3. Codebase Architecture

The entire application logic is located in the `pods.lua` file. This file is organized into distinct sections, each responsible for a specific aspect of the application.

### 3.1. Section Structure in `pods.lua`

Code in `pods.lua` is structured into sections using comment headers. When adding or modifying code, ensure it is placed in the appropriate section.

```lua
-- ------------------------------------------------------------------------- --
--
--
--         SECTION MySection
--
--
-- ------------------------------------------------------------------------- --
```

### 3.2. Section Descriptions and Naming Conventions

Each section has a specific purpose and a strict function naming convention.

| Section     | Purpose                                       | Function Prefix | Notes                                        |
|-------------|-----------------------------------------------|-----------------|----------------------------------------------|
| **Print**   | Handles all output to the command line.       | `print_`        |                                              |
| **String**  | Provides utility functions for strings.       | `string__`      |                                              |
| **Table**   | Provides utility functions for Lua tables.    | `table__`       |                                              |
| **Helper**  | Contains general helper functions.            | (none)          | Use unique, descriptive names.               |
| **Container**| Manages Podman container lifecycle commands.  | `container__`   | e.g., `container__create`, `container__remove` |
| **Pod**     | Manages Podman pod lifecycle commands.        | `pod__`         | e.g., `pod__create`, `pod__remove`           |
| **Recipe**  | Handles loading and processing of recipe files.| `recipe__`      |                                              |
| **Config**  | Manages the main `config.lua` file.           | `config__`      |                                              |
| **Main**    | Contains the main application entry point.    | `main__`        | The main function is named `main`.           |

## 4. Coding Style and Formatting

*   **Indentation:** Use 4 spaces for indentation, not tabs.
*   **Function Order**: When adding new functions, order them alphabetically by name within their section, as long as it does not conflict with Lua's requirement that functions must be declared before they are called.
*   **Style Consistency:** Adhere strictly to the coding style of existing code in `pods.lua`.
*   **Comments:**
    *   Add comments only to explain complex or non-obvious logic.
    *   Write all comments and variable names in English.
*   **Naming Conventions:**
    *   Follow the function naming conventions outlined in Section 3.2.
    *   Use descriptive variable names.

## 5. Versioning and Commit Messages

*   **Changelog:** Use the "Keep a Changelog" format for the `CHANGELOG.md` file. All user-facing changes must be documented.
*   **Commit Messages:** Write clear, concise, and descriptive commit messages that explain the *why* behind the change.

## 6. Project Constraints (Anti-Patterns)

This section lists practices that are strictly forbidden.

*   **Do not create new source files**: All core logic must be within `pods.lua` and all test logic must be within `test_suite.lua`. The only exception is for new test files.
*   **Do not add external dependencies**: The project must remain dependency-free.
*   **Do not use single-letter or numbered variable names**: Use descriptive names (e.g., `index` instead of `i`, `user_table` instead of `t2`). An exception is made for compact variable names when they are programmatically or mathematically idiomatic, such as using `x` and `y` for coordinates.
*   **Avoid global variables**: Use local variables whenever possible. Global variables are strongly discouraged and should only be used if absolutely necessary.
*   **Initialize variables with default values**: Avoid initializing variables with `nil`. Instead, use a sensible default value based on the expected type (e.g., `""` for a string, `0` for a number, `{}` for a table).
