# Using the JFrog MCP in Cursor

This guide explains how the **JFrog Model Context Protocol (MCP)** works in Cursor and how you can use it to interact with your JFrog Platform (Artifactory, projects, catalog, AppTrust, and related APIs) through conversational prompts.

---

## What it is

An MCP server exposes **tools** (functions) that the AI assistant can call on your behalf. The **user-jfrog** MCP connects Cursor to your JFrog instance using credentials you configure in Cursor (typically an access token and base URL).

You do **not** run MCP commands in a terminal yourself for day-to-day use—you **ask the assistant** in natural language, and the assistant invokes the appropriate tool if your request matches a supported operation.

---

## Prerequisites

1. **JFrog Platform** with permissions appropriate to the operations you need (repos, projects, catalog read, AppTrust, etc.).
2. **Cursor** configured with the JFrog MCP server (server name may appear as `user-jfrog` or `jfrog` in your MCP settings).
3. Valid **authentication** in that MCP configuration (URL, token or user credentials as required by your setup).

If a tool returns authorization errors, regenerate or broaden the token and confirm the MCP server uses the correct JFrog base URL.

---

## How to use it (typical workflow)

1. Open this repository or any project in Cursor.
2. In Chat, describe what you want in plain English.
3. Allow the assistant to call MCP tools when prompted (if your client asks for approval per tool).

### Example prompts

| Goal | Example prompt |
|------|----------------|
| List repositories | “Use JFrog MCP to list all local Maven repositories.” |
| Filter repos | “List npm repositories in project `my-proj`.” |
| Create a repo | “Create a local npm repository named `demo-npm-local` with Xray indexing enabled.” |
| Projects | “List all JFrog projects.” |
| CVE lookup | “Look up catalog details for CVE-2021-44228.” |
| Maven + risk (hybrid) | “Does my Maven project have vulnerabilities? Then use MCP to look up CVE-2021-44228.” (See [Worked example](#worked-example-does-my-maven-project-have-any-vulnerabilities) below.) |
| Artifact summary | “Get an Xray artifacts summary for path `default/my-repo/path/to/my-artifact.jar`.” |
| AppTrust | “Create an AppTrust application with key `my-app`, name `My Application`, project `my-proj`.” |

Adapt repository keys, project keys, and paths to your environment.

---

## Worked example: “Does my Maven project have any vulnerabilities?”

This question is useful to understand **when the assistant uses MCP** versus **other capabilities** (reading files in your workspace, Maven, JFrog CLI).

### What you might ask

> Does my Maven project have any vulnerabilities?

or, more explicitly for this repo:

> Check `maven-sample` for vulnerabilities. Use JFrog MCP where it helps.

### What the assistant typically does (two parts)

**1. Your workspace (not MCP)**  
The assistant can open `pom.xml` (and optionally `mvn dependency:tree`) to see declared versions. It compares those against well-known CVEs (for example **Log4j** in `log4j-core`, **fastjson** deserialization issues) and explains risk in plain language.  
That file analysis does **not** call JFrog; it is normal editor/repository context.

**2. JFrog MCP (when the answer lives in the platform)**  
MCP tools help when you need **JFrog Catalog / Xray–backed** data, for example:

| Your follow-up | MCP tool (typical) | What you get |
|----------------|-------------------|--------------|
| “Show CVE-2021-44228 in the catalog” | `list_catalog_vulnerabilities` with `cve_id` | Official catalog entry for that CVE (affected packages, context). |
| “What does Xray know about this built JAR?” | `get_artifacts_summary` with artifact **path** or **checksum** | Summary for an artifact already known to Xray (e.g. after `jf mvn` + publish to Artifactory). |
| “Which versions of `log4j-core` exist in my Artifactory?” | `get_rt_package_versions` / `get_rt_package_version` (per schema) | Package resolution data from Artifactory, not only your local POM. |

So: **MCP does not replace a full `mvn dependency-check` or Xray build scan on its own**, but it **connects questions to live JFrog data** once you know a CVE id, coordinates, or artifact location.

### Example conversation flow

1. **You:** “Does my Maven project have vulnerabilities?”  
   **Assistant:** Reads `pom.xml`, flags risky versions, suggests upgrades.

2. **You:** “Use JFrog MCP to look up CVE-2021-44228.”  
   **Assistant:** Calls `list_catalog_vulnerabilities` with that CVE id and summarizes the result.

3. **You:** “I published the WAR to `libs-release-local`; summarize it in Xray.”  
   **Assistant:** Calls `get_artifacts_summary` with the correct path (often `default/<repo>/...` per your Xray version).

### Takeaway for users

- Ask in **natural language**; the assistant picks **MCP** only when a tool matches (catalog, repos, artifact summary, etc.).  
- For **local Maven dependency risk**, you still benefit from **POM + scanner** (Xray via `jf`, CI, or other SCA). MCP shines when you need **platform-side** vulnerability and artifact intelligence.

---

## Tool categories (user-jfrog)

The exact tool names and parameters are defined by your MCP server. A typical **user-jfrog** deployment includes tools similar to the following.

### Projects

- `list_projects` — list JFrog projects.
- `get_project_info` — details for a project (requires project key).
- `create_project` — create a project (parameters per schema).

### Repositories

- `list_repositories` — optional filters: repository `type` (local, remote, virtual, federated, distribution), `packageType` (maven, npm, docker, pypi, …), or `project`.
- `create_repository` — create a repo; at minimum a valid `key`; also `rclass`, `packageType`, `url` (remote), `repositories` (virtual), `xrayIndex`, etc.

### Catalog and vulnerabilities

- `list_catalog_vulnerabilities` — query by `cve_id`.
- `list_catalog_version_vulnerabilities`, `get_catalog_package_entity`, `list_catalog_package_versions` — package- and version-oriented catalog queries.

### Artifact / package versions (Artifactory)

- `get_rt_package_versions`, `get_rt_package_version` — resolve package versions from Artifactory.

### Xray artifact summary

- `get_artifacts_summary` — summary for artifact paths and/or checksums (path format depends on your Xray version; paths often start with `default/` under Xray 3.x as described in the tool).

### Platform metadata

- `get_jfrog_global_environments` — global environments list.

### AppTrust

- `apptrust_create_application`, `apptrust_create_application_version`
- `apptrust_get_application_summary`, `apptrust_get_application_version_status`
- `apptrust_promote_version`, `apptrust_release_version`, `apptrust_rollback_version`
- `apptrust_get_version_promotion_history`

---

## Limitations

- **Not every JFrog feature** is exposed. For example, many setups do **not** include tools for **Curation policies** or full policy CRUD; those require the JFrog UI or REST APIs.
- Tools return what the platform allows for your token; **403/401** means missing scope or wrong URL.
- Some list operations may be **paginated or truncated** on the server side; check the JFrog UI for the full list when in doubt.

---

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Tool not found | MCP server not enabled or wrong server name in Cursor. |
| Auth errors | Token expired, insufficient permissions, or incorrect JFrog URL in MCP config. |
| Empty or partial data | Filters too narrow, or API limits; verify in the Platform UI. |

---

## Further reading

- [JFrog REST APIs](https://jfrog.com/help/r/jfrog-rest-apis) — underlying APIs many MCP tools wrap.
- [Get JFrog CLI](https://jfrog.com/getcli) — for scripted workflows outside Cursor MCP.

This document describes usage patterns; refer to your Cursor **MCP** settings and the tool schemas exposed by your **user-jfrog** server for authoritative parameter names and required fields.
