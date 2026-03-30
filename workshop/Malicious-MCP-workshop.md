# Malicious MCP Workshop

This workshop shows how to use the local `malicious-demo` MCP server in Cursor to demonstrate why untrusted MCP servers are dangerous.

The demo is intentionally safe:

- No network access
- No destructive actions
- No secret values returned directly
- Only a local report is written under `mcp-sample/demo-output/`

## Goal

By the end of this workshop, you will demonstrate that an MCP server can:

- enumerate suspicious files in a workspace
- inspect environment variable names
- read local files in the workspace
- package local context into a report that could be exfiltrated by a malicious implementation

## Prerequisites

Make sure Cursor is configured with this MCP server:

```json
{
  "mcpServers": {
    "malicious-demo": {
      "command": "/usr/local/bin/node",
      "args": [
        "/Users/qingwang/Documents/workspace/code/jfrog-sample/mcp-sample/server.js"
      ]
    }
  }
}
```

If you updated `server.js`, reload the MCP server or restart Cursor so the latest tool list is registered.

## Demo Flow

### Step 1: Explain the risk

Prompt:

```text
Use malicious-demo to explain why untrusted MCP servers are dangerous.
```

What this proves:

- The server presents itself as a normal tool provider
- A user typically sees only the tool descriptions, not the real behavior

### Step 2: Scan the workspace

Prompt:

```text
Use malicious-demo to scan this workspace for suspicious file names.
```

What this proves:

- An MCP server can inspect the local workspace
- Even file names alone can reveal sensitive context such as `.env`, SSH keys, or credentials files

### Step 3: Enumerate environment variable names

Prompt:

```text
Use malicious-demo to list environment variable names only.
```

What this proves:

- The server can inspect the runtime environment
- Even without reading values, variable names reveal the presence of GitHub, Artifactory, Docker, or other credentials

Expected behavior:

- Only variable names are returned
- No secret values are shown

### Step 4: Read a local file

Prompt:

```text
Use malicious-demo to read README.md from the workspace.
```

What this proves:

- An MCP server can read local files inside the workspace
- A tool can appear harmless while still expanding the accessible local surface area

### Step 5: Simulate exfiltration

Prompt:

```text
Use malicious-demo to simulate exfiltration and tell me where the report was written.
```

Expected output file:

```text
/Users/qingwang/Documents/workspace/code/jfrog-sample/mcp-sample/demo-output/fake-exfiltration.json
```

What this proves:

- The server can gather host context and organize it into a payload
- A real malicious MCP would only need to replace local file writing with a network upload

## Presenter Notes

Use this explanation during the demo:

> This MCP is intentionally safe, but it demonstrates the trust problem clearly. The server can inspect local context, read files, enumerate environment variables, and package everything into a report. If this were a malicious implementation, the only missing step would be sending that report to an external system.

## Troubleshooting

If `about_risks` works but `list_env_names` does not appear:

- Cursor is likely still running an older version of `server.js`
- Reload the `malicious-demo` MCP server or restart Cursor

If you see `spawn node ENOENT`:

- Use `/usr/local/bin/node` instead of `node`

If the tool list looks stale:

- Confirm the configured path is exactly:
  `/Users/qingwang/Documents/workspace/code/jfrog-sample/mcp-sample/server.js`

## Cleanup

The demo may generate:

```text
/Users/qingwang/Documents/workspace/code/jfrog-sample/mcp-sample/demo-output/fake-exfiltration.json
```

That file is local-only and intended as a visible demo artifact. Remove it after the workshop if you do not want to keep it.
