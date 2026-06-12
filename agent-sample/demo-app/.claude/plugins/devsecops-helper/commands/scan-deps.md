---
description: Scan the project's dependencies for known vulnerabilities using JFrog Xray
---

Scan this project's dependencies for security vulnerabilities.

Steps:

1. Detect the package manager used by this project (npm, Maven, Gradle, pip, Go, etc.) by looking for manifest files (`package.json`, `pom.xml`, `build.gradle`, `requirements.txt`, `go.mod`).
2. If the JFrog CLI (`jf`) is available and configured, run `jf audit` from the project root and summarize the results: total issues by severity, the top 5 most critical findings, and the recommended fixed versions.
3. If `jf` is not available, statically review the dependency manifest for pinned versions that are known to be outdated or risky, and recommend running `jf audit` after installing the JFrog CLI.
4. Finish with a short, actionable remediation list ordered by severity.
