# JFrog Agent Plugins Repository — Demo

End-to-end demo of [Agent Plugins Repositories](https://docs.jfrog.com/artifactory/docs/agent-plugins-repositories) (beta) in JFrog Artifactory: publish a multi-harness coding-agent plugin and install it for Claude Code / Cursor / Codex.

## Environment

| Item | Value |
|------|-------|
| JFrog server | `--server-id` configured via `jf config` (URL: `https://<YOUR_JFROG_HOST>`) |
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
├── .claude-plugin/marketplace.json  # local-fs marketplace, for installing into Claude Code
├── demo-app/                    # a "consumer" project the plugin gets installed into
└── scripts/
    ├── publish.sh               # publish to Artifactory
    ├── install.sh               # install from Artifactory into demo-app (jf, any harness)
    └── install-claude-plugin.sh # install into Claude Code via the local-fs marketplace
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

### 2. Discover plugins

```bash
jf agent plugins list --repo alex-agent-plugins-local --server-id soleng
jf agent plugins search devsecops-helper --repo alex-agent-plugins-local --server-id soleng
```

### 3. Install into a project (JFrog CLI, works for all harnesses)

```bash
# this plugin is published unsigned, so allow install without evidence
export JFROG_AGENT_PLUGINS_DISABLE_QUIET_FAILURE=true

jf agent plugins install devsecops-helper \
  --repo alex-agent-plugins-local --server-id soleng \
  --harness claude --project-dir ./demo-app
```

- Valid harness names: `claude`, `cursor`, `codex` (comma-separated for multi-install).
  Custom harnesses can be added in `~/.jfrog/agents/agent-config.json`.
- Files land in `demo-app/.claude/plugins/devsecops-helper/`, with install metadata
  in `.jfrog/plugin-info.json`.
- `--global` installs to `~/.claude/plugins` instead; `--version 1.0.0` pins a version.
- The CLI verifies evidence at install time; since this plugin is unsigned, set
  `JFROG_AGENT_PLUGINS_DISABLE_QUIET_FAILURE=true` to proceed (a warning is printed).

### 4. Native Claude Code marketplace integration

Claude Code can register the repository directly as a plugin marketplace. The
basic-auth username must match the access-token subject (find it by decoding the
JWT payload of your token, or via your platform user profile):

```bash
claude plugin marketplace add \
  "https://<USERNAME>:<TOKEN>@<YOUR_JFROG_HOST>/artifactory/api/agentplugins/alex-agent-plugins-local/claude-marketplace.json"
```

> ⚠️ **Known compatibility gap (as of Claude Code 2.1.174 + Artifactory beta).**
> `marketplace add` succeeds, but `claude plugin install devsecops-helper@...`
> currently **fails**. Artifactory's marketplace JSON publishes the plugin with
> `"source": "url"` pointing to a **ZIP**, whereas Claude Code's `url` source type
> means a **git repository** (it runs `git clone`) — there is no zip-download
> source type yet. So Claude tries to `git clone` the `.zip` and fails.
> `claude plugin validate` passes (the schema is legal); only install behavior is
> incompatible.
>
> For private remote hosting that Claude Code installs from natively today,
> the supported sources are a **git repo** (`source: "url"`/`github`/`git-subdir`)
> or an **npm package** (`source: "npm"` against an Artifactory npm registry).

#### Install into Claude Code today (verified working)

Because of the gap above, load the plugin via a **local-filesystem marketplace**
that points at the plugin folder — Claude Code supports a local `source` path
natively. This repo ships [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)
(marketplace name `alex-agent-plugins-local-fs`, plugin source `./devsecops-helper`)
for exactly that.

```bash
# 0. (one-time) install the Claude Code CLI if you don't have it
curl -fsSL https://claude.ai/install.sh | bash          # installs to ~/.local/bin/claude

# 1. register this repo as a local marketplace (absolute path required)
claude plugin marketplace add /path/to/agent-sample   # absolute path to this repo

# 2. install the plugin from that marketplace (user scope)
claude plugin install devsecops-helper@alex-agent-plugins-local-fs

# 3. restart Claude Code, then verify
claude plugin list                    # shows devsecops-helper@alex-agent-plugins-local-fs (1.0.0)
claude plugin details devsecops-helper # lists components: scan-deps, release-notes
```

Or run the wrapper script, which does all of the above (idempotent — installs the
`claude` CLI if missing, then registers the marketplace and installs the plugin):

```bash
./scripts/install-claude-plugin.sh
```

After restarting Claude Code, the plugin's components are live:

- `/scan-deps` — slash command
- `release-notes` — skill (invoked automatically when you ask for release notes)

Useful management commands:

```bash
claude plugin marketplace update alex-agent-plugins-local-fs   # re-read marketplace.json after edits
claude plugin uninstall devsecops-helper                      # remove
claude plugin marketplace remove alex-agent-plugins-local-fs  # detach the marketplace
```

### 5. Download a plugin from Artifactory

Three ways, from highest-level to raw download.

**a) JFrog CLI install (recommended — any harness)**

Downloads the ZIP and extracts it to the harness's plugin directory:

```bash
jf agent plugins install devsecops-helper \
  --repo alex-agent-plugins-local --server-id soleng --harness claude

# variations
--harness claude,cursor,codex   # several agents at once
--global                        # to ~/.claude/plugins instead of the project
--project-dir ./my-app          # a specific project root
--version 1.0.0                 # pin a version (default: latest)
--path ./plugins                # raw extract to <path>/<slug>, no harness layout
```

**b) Claude Code marketplace (see step 4)**

Register the repo as a marketplace and install via the `claude` CLI. Note the
compatibility gap in step 4: installing directly from the Artifactory
`claude-marketplace.json` currently fails (zip-url vs git-url), so today this goes
through the local-filesystem marketplace shipped in this repo. (Cursor and Codex
have no native marketplace registration yet — use method a.)

**c) Raw ZIP download (CI, scripting, inspection)**

The plugin is a plain artifact at `<name>/<version>/<name>-<version>.zip`:

```bash
# JFrog CLI
jf rt dl "alex-agent-plugins-local/devsecops-helper/1.0.0/devsecops-helper-1.0.0.zip" --server-id soleng

# or plain curl
curl -H "Authorization: Bearer $TOKEN" \
  -O "https://<YOUR_JFROG_HOST>/artifactory/alex-agent-plugins-local/devsecops-helper/1.0.0/devsecops-helper-1.0.0.zip"

# list available versions (no per-version index file in the beta)
jf rt curl -s "/api/storage/alex-agent-plugins-local/devsecops-helper" --server-id soleng \
  | jq -r '.children[].uri'
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
3. **Beta limitations** — local repositories only (no remote/virtual), path-driven indexing (folder names win over manifest values), no per-version index file.
