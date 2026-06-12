# JFrog Agent Plugins Repository — Demo

End-to-end demo of [Agent Plugins Repositories](https://docs.jfrog.com/artifactory/docs/agent-plugins-repositories) (beta) in JFrog Artifactory: publish a multi-harness coding-agent plugin, sign it with evidence, and install it for Claude Code / Cursor / Codex.

## Environment

| Item | Value |
|------|-------|
| JFrog server | `soleng` (`https://solenglatest.jfrog.io`) |
| Repository | `alex-agent-plugins-local` (package type: `agentplugins`, local) |
| JFrog CLI | ≥ 2.108.0 (`jf agent plugins` namespace) |
| Sample plugin | [`devsecops-helper/`](devsecops-helper/) |

## Project layout

```
agent-sample/
├── devsecops-helper/            # the sample plugin (source)
│   ├── .claude-plugin/plugin.json    # Claude Code manifest
│   ├── .cursor-plugin/plugin.json    # Cursor manifest
│   ├── .codex-plugin/plugin.json     # Codex manifest (all three: same name + version)
│   ├── commands/scan-deps.md         # /scan-deps slash command
│   └── skills/release-notes/SKILL.md # release-notes skill
├── demo-app/                    # a "consumer" project the plugin gets installed into
├── keys/                        # evidence signing key pair (private key is git-ignored)
└── scripts/
    ├── publish.sh               # publish (optionally signed) to Artifactory
    └── install.sh               # install from Artifactory into demo-app
```

## Demo walkthrough

### 1. Publish the plugin

```bash
jf agent plugins publish ./devsecops-helper --repo alex-agent-plugins-local --server-id soleng
```

Artifactory stores the plugin as a ZIP under the strict path convention
`<name>/<version>/<name>-<version>.zip` and **automatically generates marketplace
index files** at the repository root:

- `marketplace.json` — all plugins
- `claude-marketplace.json` / `cursor-marketplace.json` / `codex-marketplace.json` — per-harness

Each index references only the **latest semver version** per plugin.

### 2. Publish a signed version (evidence)

One-time setup — register the public key as a platform trusted key:

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/evidence-private.pem
openssl pkey -in keys/evidence-private.pem -pubout -out keys/evidence-public.pem

jq -n --arg alias "alex-demo-evidence-key" --rawfile pk keys/evidence-public.pem \
  '{alias: $alias, public_key: $pk}' \
  | jf rt curl -XPOST /api/security/keys/trusted -H "Content-Type: application/json" -d @- --server-id soleng
```

> Note: ED25519 is rejected by the trusted-keys API ("Unsupported trusted key type") — use RSA.

Then publish with signing:

```bash
jf agent plugins publish ./devsecops-helper \
  --repo alex-agent-plugins-local --server-id soleng \
  --signing-key keys/evidence-private.pem \
  --key-alias alex-demo-evidence-key
```

Output: `Evidence successfully attached.`

### 3. Discover plugins

```bash
jf agent plugins list --repo alex-agent-plugins-local --server-id soleng
jf agent plugins search devsecops-helper --repo alex-agent-plugins-local --server-id soleng
```

### 4. Install into a project (JFrog CLI, works for all harnesses)

```bash
jf agent plugins install devsecops-helper \
  --repo alex-agent-plugins-local --server-id soleng \
  --harness claude --project-dir ./demo-app
```

- Valid harness names: `claude`, `cursor`, `codex` (comma-separated for multi-install).
  Custom harnesses can be added in `~/.jfrog/agents/agent-config.json`.
- Files land in `demo-app/.claude/plugins/devsecops-helper/`, with install metadata
  in `.jfrog/plugin-info.json`.
- `--global` installs to `~/.claude/plugins` instead; `--version 1.0.0` pins a version.
- **Evidence is verified at install time.** Installing an unsigned plugin fails with
  `evidence verification failed ... no evidence found`. To allow unsigned plugins:
  `export JFROG_AGENT_PLUGINS_DISABLE_QUIET_FAILURE=true` (a warning is printed instead).

### 5. Native Claude Code marketplace integration

Claude Code can consume the repository directly as a plugin marketplace:

```bash
claude plugin marketplace add \
  "https://<USER>:<TOKEN>@solenglatest.jfrog.io/artifactory/api/agentplugins/alex-agent-plugins-local/claude-marketplace.json"
```

Then inside Claude Code:

```
/plugin   →  browse the marketplace and install devsecops-helper
```

### 6. Try the plugin

Open Claude Code in `demo-app/` — the plugin provides:

- `/scan-deps` — scans project dependencies for vulnerabilities via `jf audit`
- `release-notes` skill — generates release notes from git history

### 7. Update / delete

```bash
jf agent plugins update devsecops-helper --harness claude --project-dir ./demo-app
jf agent plugins delete devsecops-helper --version 1.0.0 --repo alex-agent-plugins-local --server-id soleng
```

## Key takeaways

1. **One repo, three agents** — a single multi-harness plugin serves Claude Code, Cursor, and Codex; all manifests must declare identical `name` and `version`.
2. **Zero-effort marketplace** — Artifactory maintains the per-harness marketplace JSON automatically on every publish.
3. **Supply-chain security built in** — plugins are signed with evidence at publish time and verified at install time, backed by platform trusted keys.
4. **Beta limitations** — local repositories only (no remote/virtual), path-driven indexing (folder names win over manifest values), no per-version index file.
