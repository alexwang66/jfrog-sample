---
name: release-notes
description: Generate professional release notes from git history. Use when the user asks to draft release notes, a changelog entry, or a release summary for a tag or version.
---

# Release Notes Generator

Generate clear, professional release notes from the project's git history.

## Workflow

1. Determine the range: from the previous tag (`git describe --tags --abbrev=0`) to `HEAD`, unless the user specifies a range.
2. Collect commits: `git log <range> --pretty=format:'%h %s (%an)'`.
3. Group the changes into sections:
   - **Features** — commits starting with `feat`
   - **Bug Fixes** — commits starting with `fix`
   - **Security** — commits mentioning CVE, vulnerability, or dependency upgrades
   - **Other Changes** — everything else meaningful (skip merge commits and version bumps)
4. Write the release notes in Markdown with the version number and date as the title.
5. Keep each bullet to one sentence, written for end users, not for developers.

## Style rules

- Lead with user-visible impact, not implementation detail.
- Never invent changes that are not in the git history.
- If the range contains no commits, say so instead of producing an empty template.
