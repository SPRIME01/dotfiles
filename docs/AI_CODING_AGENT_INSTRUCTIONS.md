# AI Coding Agent Instructions

This document provides instructions for an AI coding agent to resolve the technical debt issues identified in the `docs/TECHNICAL_DEBT_REPORT.md` file.

## Instructions

You are an AI coding agent. Your task is to resolve the technical debt issues identified in the `docs/TECHNICAL_DEBT_REPORT.md` file. For each issue, you must:

1.  Read the issue description and the recommended solution.
2.  Scan the entire project to identify all files that exhibit the issue.
3.  Apply the recommended solution to all identified files.
4.  Ensure that your changes do not introduce any new technical debt or issues.
5.  Verify your changes by running the project's linter and test suite.

Here are the issues you need to resolve:

### 1. Inconsistent Coding Styles

*   **Issue:** There are some inconsistencies in the coding style of the shell scripts. For example, some scripts use `#!/usr/bin/env bash` while others use `#!/bin/bash`.
*   **Recommendation:** Adopt a consistent coding style for all shell scripts and enforce it using a linter like `shellcheck`.
*   **Instructions:**
    1.  Scan all shell scripts in the project and ensure that they all use `#!/usr/bin/env bash`.
    2.  Run `shellcheck` on all shell scripts and fix any reported issues.

### 2. Duplicate Code

*   **Issue:** The `DOTFILES` variable is defined multiple times in `bootstrap.sh`.
*   **Recommendation:** Define the `DOTFILES` variable only once and reuse it throughout the script.
*   **Instructions:**
    1.  In `bootstrap.sh`, remove the duplicate definitions of the `DOTFILES` variable.
    2.  Ensure that the `DOTFILES` variable is defined only once, at the beginning of the script.

### 3. Hardcoded Paths

*   **Issue:** The scripts use `~` for the home directory instead of `$HOME`.
*   **Recommendation:** Use `$HOME` instead of `~` for the home directory.
*   **Instructions:**
    1.  Scan all shell scripts in the project and replace all instances of `~` with `$HOME`.

### 4. Lack of Error Handling

*   **Issue:** The scripts could benefit from more specific error handling and user feedback.
*   **Recommendation:** Add more specific error handling and user feedback to the scripts.
*   **Instructions:**
    1.  In `bootstrap.sh`, add a check to see if the symlinks were created successfully. If not, print an error message and exit.
    2.  Review other scripts and add error handling where appropriate.

### 5. Network Dependency

*   **Issue:** The scripts' dependency on a network connection could be problematic in offline environments.
*   **Recommendation:** Make the scripts more robust to network failures and use the `NO_NETWORK` flag consistently.
*   **Instructions:**
    1.  In `bootstrap.sh`, ensure that the `NO_NETWORK` flag is checked before attempting to install any software from the network.
    2.  Review other scripts and add similar checks where appropriate.

### 6. Clarity of Output

*   **Issue:** The scripts could provide more detailed information about what they're doing.
*   **Recommendation:** Improve the clarity of the scripts' output.
*   **Instructions:**
    1.  In `bootstrap.sh`, add `echo` statements to indicate which symlinks are being created.
    2.  Review other scripts and add `echo` statements to improve the clarity of their output.

### 7. Incomplete `doctor.sh` script

*   **Issue:** The `doctor.sh` script is missing the `check_optional` function and could be more comprehensive.
*   **Recommendation:** Complete the `doctor.sh` script and make it more comprehensive.
*   **Instructions:**
    1.  In `scripts/doctor.sh`, implement the `check_optional` function.
    2.  Add checks for the existence of symlinks, the versions of installed tools, and the status of the network connection.

### 8. Basic CI/CD Pipeline

*   **Issue:** The CI/CD pipeline could be improved by caching dependencies, running jobs in parallel, adding more tests, and adding a deployment step.
*   **Recommendation:** Improve the CI/CD pipeline to make it more efficient and effective.
*   **Instructions:**
    1.  In `.github/workflows/ci.yml`, add caching for `apt` and `brew` dependencies.
    2.  Modify the workflow to run the `lint` and `test` jobs in parallel.
    3.  (Optional) Add a deployment step to the workflow.

### 9. No Clear Versioning

*   **Issue:** There is no clear versioning strategy for the dotfiles.
*   **Recommendation:** Adopt a versioning strategy for the dotfiles, such as semantic versioning.
*   **Instructions:**
    1.  This issue requires a manual decision on the versioning strategy. Once a strategy is chosen, it should be documented in the `README.md` file.

### 10. Lack of Documentation for Some Scripts

*   **Issue:** Some of the scripts are not well-documented.
*   **Recommendation:** Add documentation to all scripts, explaining what they do and how to use them.
*   **Instructions:**
    1.  Review all scripts in the project and add a header comment to each script that explains its purpose, inputs, and outputs.