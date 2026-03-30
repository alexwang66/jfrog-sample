#!/usr/bin/env node

import fs from "fs";
import os from "os";
import path from "path";

const serverInfo = {
  name: "malicious-demo-mcp",
  version: "1.0.0"
};

const protocolVersion = "2024-11-05";
const workspaceRoot = process.cwd();
const demoOutputDir = path.join(workspaceRoot, "mcp-sample", "demo-output");
const debugLogPath = "/tmp/mcp-sample-debug.log";

appendDebug(`startup pid=${process.pid} cwd=${workspaceRoot}`);

const heartbeat = setInterval(() => {
  appendDebug("heartbeat");
}, 10000);

if (typeof heartbeat.unref === "function") {
  heartbeat.unref();
}

process.on("exit", (code) => {
  appendDebug(`exit code=${code}`);
});

process.on("SIGINT", () => {
  appendDebug("signal SIGINT");
  process.exit(0);
});

process.on("SIGTERM", () => {
  appendDebug("signal SIGTERM");
  process.exit(0);
});

process.on("uncaughtException", (error) => {
  appendDebug(`uncaughtException ${error.stack || error.message}`);
  process.exit(1);
});

process.on("unhandledRejection", (reason) => {
  appendDebug(`unhandledRejection ${String(reason)}`);
  process.exit(1);
});

const tools = [
  {
    name: "about_risks",
    description: "Explain why an untrusted MCP server is risky even if it looks helpful.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {}
    }
  },
  {
    name: "scan_workspace_summary",
    description: "Summarize potentially sensitive files in the current workspace without reading file contents.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {
        maxResults: {
          type: "integer",
          minimum: 1,
          maximum: 200,
          default: 30
        }
      }
    }
  },
  {
    name: "list_env_names",
    description: "List environment variable names only. Values are never returned.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {
        onlySensitive: {
          type: "boolean",
          default: true
        }
      }
    }
  },
  {
    name: "read_local_file",
    description: "Read a local file relative to the workspace to demonstrate that MCP tools can access arbitrary files you approve.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      required: ["relativePath"],
      properties: {
        relativePath: {
          type: "string",
          description: "Path relative to the current workspace."
        },
        maxBytes: {
          type: "integer",
          minimum: 1,
          maximum: 32768,
          default: 4096
        }
      }
    }
  },
  {
    name: "stage_fake_exfiltration",
    description: "Write a local JSON report that simulates exfiltration. This demo never sends data over the network.",
    inputSchema: {
      type: "object",
      additionalProperties: false,
      properties: {
        includeEnv: {
          type: "boolean",
          default: true
        },
        includeGit: {
          type: "boolean",
          default: true
        }
      }
    }
  }
];

let buffer = Buffer.alloc(0);

process.stdin.on("data", (chunk) => {
  appendDebug(`chunk bytes=${chunk.length}`);
  appendDebug(chunk.toString("utf8"));
  buffer = Buffer.concat([buffer, chunk]);
  processBuffer();
});

process.stdin.on("end", () => process.exit(0));

function processBuffer() {
  while (true) {
    const parsed = parseMessage(buffer);
    if (!parsed) {
      return;
    }

    const { body, remaining } = parsed;
    buffer = remaining;

    let message;
    try {
      message = JSON.parse(body);
    } catch (error) {
      sendError(null, -32700, `Invalid JSON: ${error.message}`);
      continue;
    }

    void handleMessage(message);
  }
}

function parseMessage(input) {
  const lineResult = parseLineDelimitedMessage(input);
  if (lineResult) {
    return lineResult;
  }

  const text = input.toString("utf8");
  const lfIndex = text.indexOf("\n\n");
  const crlfIndex = text.indexOf("\r\n\r\n");

  let separatorIndex = -1;
  let separatorLength = 0;

  if (crlfIndex !== -1 && (lfIndex === -1 || crlfIndex < lfIndex)) {
    separatorIndex = crlfIndex;
    separatorLength = 4;
  } else if (lfIndex !== -1) {
    separatorIndex = lfIndex;
    separatorLength = 2;
  }

  if (separatorIndex === -1) {
    return null;
  }

  const headerText = text.slice(0, separatorIndex);
  const headers = parseHeaders(headerText);
  const contentLengthHeader = headers["content-length"];
  if (!contentLengthHeader) {
    throw new Error("Missing Content-Length header");
  }

  const contentLength = Number.parseInt(contentLengthHeader, 10);
  if (Number.isNaN(contentLength) || contentLength < 0) {
    throw new Error("Invalid Content-Length header");
  }

  const bodyStart = separatorIndex + separatorLength;
  const bodyEnd = bodyStart + contentLength;
  if (input.length < bodyEnd) {
    return null;
  }

  return {
    body: input.subarray(bodyStart, bodyEnd).toString("utf8"),
    remaining: input.subarray(bodyEnd)
  };
}

function parseLineDelimitedMessage(input) {
  const text = input.toString("utf8");
  const newlineIndex = text.indexOf("\n");
  if (newlineIndex === -1) {
    return null;
  }

  const firstLine = text.slice(0, newlineIndex).trim();
  if (!firstLine.startsWith("{")) {
    return null;
  }

  try {
    JSON.parse(firstLine);
  } catch {
    return null;
  }

  return {
    body: firstLine,
    remaining: input.subarray(Buffer.byteLength(text.slice(0, newlineIndex + 1), "utf8"))
  };
}

function parseHeaders(headerText) {
  const headers = {};
  for (const rawLine of headerText.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line) {
      continue;
    }

    const colonIndex = line.indexOf(":");
    if (colonIndex === -1) {
      continue;
    }

    const key = line.slice(0, colonIndex).trim().toLowerCase();
    const value = line.slice(colonIndex + 1).trim();
    headers[key] = value;
  }

  return headers;
}

async function handleMessage(message) {
  if (!message || typeof message !== "object") {
    return;
  }

  debugLog(`recv ${message.method ?? "unknown-method"}`);

  if (message.method === "notifications/initialized") {
    return;
  }

  if (!Object.hasOwn(message, "id")) {
    return;
  }

  try {
    switch (message.method) {
      case "initialize":
        sendResult(message.id, {
          protocolVersion: message.params?.protocolVersion || protocolVersion,
          capabilities: {
            tools: {}
          },
          serverInfo
        });
        return;
      case "tools/list":
        sendResult(message.id, { tools });
        return;
      case "tools/call":
        sendResult(message.id, await callTool(message.params ?? {}));
        return;
      default:
        sendError(message.id, -32601, `Method not found: ${message.method}`);
    }
  } catch (error) {
    sendError(message.id, -32000, error.message);
  }
}

async function callTool(params) {
  const name = params.name;
  const args = params.arguments ?? {};

  switch (name) {
    case "about_risks":
      return textResult([
        "This MCP is intentionally designed as a warning demo.",
        "An MCP server runs code you choose to trust, and its tools can be shaped to look useful while accessing sensitive data.",
        "Common risk areas: local files, environment variables, git remotes, SSH config, cloud credentials, and generated secrets in the workspace.",
        "This sample avoids network access and only writes a local preview file so the behavior stays visible and reversible."
      ].join("\n"));
    case "scan_workspace_summary":
      return handleScanWorkspace(args);
    case "list_env_names":
      return handleListEnvNames(args);
    case "read_local_file":
      return handleReadLocalFile(args);
    case "stage_fake_exfiltration":
      return handleStageFakeExfiltration(args);
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

function handleScanWorkspace(args) {
  const maxResults = toInteger(args.maxResults, 30, 1, 200);
  const interestingNames = [
    ".env",
    ".env.local",
    ".npmrc",
    ".pypirc",
    ".netrc",
    "id_rsa",
    "id_ed25519",
    "credentials",
    "config.json",
    "secrets.yml"
  ];
  const findings = [];

  walk(workspaceRoot, (entryPath, stat) => {
    if (findings.length >= maxResults) {
      return false;
    }

    const baseName = path.basename(entryPath);
    if (
      interestingNames.includes(baseName) ||
      baseName.toLowerCase().includes("secret") ||
      baseName.toLowerCase().includes("token") ||
      baseName.toLowerCase().includes("credential")
    ) {
      findings.push({
        path: path.relative(workspaceRoot, entryPath),
        kind: stat.isDirectory() ? "directory" : "file",
        bytes: stat.isFile() ? stat.size : null
      });
    }

    return true;
  });

  return textResult(
    JSON.stringify(
      {
        workspaceRoot,
        totalFindings: findings.length,
        findings
      },
      null,
      2
    )
  );
}

function handleListEnvNames(args) {
  const onlySensitive = args.onlySensitive !== false;
  const envNames = Object.keys(process.env).sort();
  const filteredNames = onlySensitive
    ? envNames.filter((key) => /(token|secret|key|password|credential)/i.test(key))
    : envNames;

  return textResult(
    JSON.stringify(
      {
        total: filteredNames.length,
        names: filteredNames
      },
      null,
      2
    )
  );
}

function handleReadLocalFile(args) {
  if (!args.relativePath || typeof args.relativePath !== "string") {
    throw new Error("relativePath is required");
  }

  const maxBytes = toInteger(args.maxBytes, 4096, 1, 32768);
  const targetPath = path.resolve(workspaceRoot, args.relativePath);
  if (!targetPath.startsWith(workspaceRoot)) {
    throw new Error("Path escapes the workspace");
  }

  const stat = fs.statSync(targetPath);
  if (!stat.isFile()) {
    throw new Error("Target is not a file");
  }

  const content = fs.readFileSync(targetPath, "utf8").slice(0, maxBytes);
  return textResult(
    JSON.stringify(
      {
        path: path.relative(workspaceRoot, targetPath),
        size: stat.size,
        preview: content
      },
      null,
      2
    )
  );
}

function handleStageFakeExfiltration(args) {
  const includeEnv = args.includeEnv !== false;
  const includeGit = args.includeGit !== false;
  fs.mkdirSync(demoOutputDir, { recursive: true });

  const report = {
    generatedAt: new Date().toISOString(),
    hostname: os.hostname(),
    user: os.userInfo().username,
    cwd: workspaceRoot,
    note: "Demo only. No network transmission occurred.",
    envPreview: includeEnv ? collectEnvPreview() : [],
    gitPreview: includeGit ? collectGitPreview() : null
  };

  const reportPath = path.join(demoOutputDir, "fake-exfiltration.json");
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

  return textResult(
    JSON.stringify(
      {
        reportPath,
        summary: "A local report was written to simulate how an MCP server could package sensitive context."
      },
      null,
      2
    )
  );
}

function collectEnvPreview() {
  const suspiciousKeys = Object.keys(process.env)
    .filter((key) => /(token|secret|key|password|credential)/i.test(key))
    .sort();

  return suspiciousKeys.map((key) => ({
    key,
    preview: redact(process.env[key] ?? "")
  }));
}

function collectGitPreview() {
  const gitConfigPath = path.join(workspaceRoot, ".git", "config");
  if (!fs.existsSync(gitConfigPath)) {
    return null;
  }

  const content = fs.readFileSync(gitConfigPath, "utf8");
  const remotes = [...content.matchAll(/url\s*=\s*(.+)/g)].map((match) => match[1].trim());
  return { remotes };
}

function walk(rootPath, visitor) {
  const entries = fs.readdirSync(rootPath, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name === ".git" || entry.name === "node_modules" || entry.name === "demo-output") {
      continue;
    }

    const fullPath = path.join(rootPath, entry.name);
    const stat = fs.statSync(fullPath);
    const shouldContinue = visitor(fullPath, stat);
    if (shouldContinue === false) {
      return false;
    }

    if (stat.isDirectory()) {
      const nested = walk(fullPath, visitor);
      if (nested === false) {
        return false;
      }
    }
  }

  return true;
}

function redact(value) {
  if (!value) {
    return "";
  }
  if (value.length <= 6) {
    return "***";
  }
  return `${value.slice(0, 3)}***${value.slice(-2)}`;
}

function toInteger(value, fallback, min, max) {
  const parsed = Number.parseInt(value ?? fallback, 10);
  if (Number.isNaN(parsed)) {
    return fallback;
  }
  return Math.min(max, Math.max(min, parsed));
}

function textResult(text) {
  return {
    content: [
      {
        type: "text",
        text
      }
    ]
  };
}

function sendResult(id, result) {
  debugLog(`send result for id=${id}`);
  sendMessage({
    jsonrpc: "2.0",
    id,
    result
  });
}

function sendError(id, code, message) {
  debugLog(`send error for id=${id}: ${message}`);
  sendMessage({
    jsonrpc: "2.0",
    id,
    error: { code, message }
  });
}

function sendMessage(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function debugLog(message) {
  process.stderr.write(`[mcp-sample] ${message}\n`);
  appendDebug(message);
}

function appendDebug(message) {
  try {
    fs.appendFileSync(debugLogPath, `${new Date().toISOString()} ${message}\n`);
  } catch {
    // Ignore debug logging failures.
  }
}
