# devsecops-helper

A sample multi-harness agent plugin used to demonstrate **JFrog Artifactory Agent Plugins repositories**.

## What's inside

| Component | Path | What it does |
|-----------|------|--------------|
| Slash command | `commands/scan-deps.md` | `/scan-deps` — scans project dependencies for vulnerabilities via `jf audit` |
| Skill | `skills/release-notes/SKILL.md` | Generates release notes from git history |

## Supported harnesses

This plugin declares manifests for three coding agents (all with identical `name` and `version`, as required for multi-harness plugins):

- `.claude-plugin/plugin.json` — Claude Code
- `.cursor-plugin/plugin.json` — Cursor
- `.codex-plugin/plugin.json` — Codex

## Publish

```bash
jf agent plugins publish ./devsecops-helper --repo alex-agent-plugins-local
```
