#!/usr/bin/env node

// HTTP server that wraps @playwright/mcp as a subprocess.
// Translates simple HTTP POST requests to MCP JSON-RPC tool calls.

import { spawn } from "node:child_process";
import http from "node:http";
import { createInterface } from "node:readline";
import fs from "node:fs";
import path from "node:path";

const SESSION_DIR = "/tmp/pw-sessions";
const headless = process.argv.includes("--headless");
const readyFile = process.env.PW_READY_FILE;

fs.mkdirSync(SESSION_DIR, { recursive: true });

// --- MCP subprocess ---

const mcpArgs = ["--yes", "@playwright/mcp@latest"];
if (headless) mcpArgs.push("--headless");

const mcp = spawn("npx", mcpArgs, {
  stdio: ["pipe", "pipe", "inherit"],
});

const pending = new Map();
let nextId = 1;

const rl = createInterface({ input: mcp.stdout });
rl.on("line", (line) => {
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return;
  }
  if (msg.id != null && pending.has(msg.id)) {
    const { resolve, reject, timer } = pending.get(msg.id);
    clearTimeout(timer);
    pending.delete(msg.id);
    if (msg.error) {
      reject(new Error(msg.error.message || JSON.stringify(msg.error)));
    } else {
      resolve(msg.result);
    }
  }
});

function rpc(method, params, timeout = 60000) {
  return new Promise((resolve, reject) => {
    const id = nextId++;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`Timeout: ${method}`));
    }, timeout);
    pending.set(id, { resolve, reject, timer });
    mcp.stdin.write(
      JSON.stringify({ jsonrpc: "2.0", method, params, id }) + "\n",
    );
  });
}

function notify(method, params) {
  mcp.stdin.write(JSON.stringify({ jsonrpc: "2.0", method, params }) + "\n");
}

// --- HTTP server ---

function readBody(req) {
  return new Promise((resolve) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => resolve(Buffer.concat(chunks).toString()));
  });
}

function extractContent(result) {
  if (!result?.content) return "";
  const parts = [];
  for (const item of result.content) {
    if (item.type === "text") {
      parts.push(item.text);
    } else if (item.type === "image") {
      const ext = item.mimeType === "image/jpeg" ? "jpg" : "png";
      const file = `/tmp/pw-screenshot-${Date.now()}.${ext}`;
      fs.writeFileSync(file, Buffer.from(item.data, "base64"));
      parts.push(`Screenshot saved: ${file}`);
    }
  }
  return parts.join("\n");
}

const httpServer = http.createServer(async (req, res) => {
  if (req.method === "GET" && req.url === "/health") {
    res.writeHead(200);
    return res.end("ok");
  }
  if (req.method !== "POST") {
    res.writeHead(405);
    return res.end("Method not allowed");
  }

  const body = await readBody(req);
  let parsed;
  try {
    parsed = JSON.parse(body);
  } catch {
    res.writeHead(400);
    return res.end("Invalid JSON");
  }

  const { tool, args: toolArgs } = parsed;
  if (!tool) {
    res.writeHead(400);
    return res.end("Missing 'tool' field");
  }

  if (tool === "__shutdown") {
    res.writeHead(200);
    res.end("Shutting down");
    shutdown();
    return;
  }

  try {
    const result = await rpc("tools/call", {
      name: tool,
      arguments: toolArgs || {},
    });
    const output = extractContent(result);
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end(output);
  } catch (err) {
    res.writeHead(500);
    res.end(`Error: ${err.message}`);
  }
});

// --- Lifecycle ---

let shuttingDown = false;

function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  const port = httpServer.address()?.port;
  try {
    if (port) fs.unlinkSync(path.join(SESSION_DIR, `${port}.json`));
  } catch {}
  try {
    mcp.kill();
  } catch {}
  setTimeout(() => process.exit(0), 200);
}

mcp.on("exit", (code) => {
  if (code !== 0 && !shuttingDown) {
    process.stderr.write(`MCP process exited with code ${code}\n`);
  }
  shutdown();
});

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

// --- Main ---

async function main() {
  // MCP initialization handshake
  await rpc("initialize", {
    protocolVersion: "2024-11-05",
    capabilities: {},
    clientInfo: { name: "pw-driver", version: "1.0.0" },
  });
  notify("notifications/initialized");

  // Start HTTP server on random port
  await new Promise((resolve) => httpServer.listen(0, "127.0.0.1", resolve));
  const port = httpServer.address().port;

  // Write session file
  fs.writeFileSync(
    path.join(SESSION_DIR, `${port}.json`),
    JSON.stringify({
      port,
      pid: process.pid,
      mcpPid: mcp.pid,
      headless,
      started: new Date().toISOString(),
    }),
  );

  // Signal ready
  if (readyFile) {
    fs.writeFileSync(readyFile, String(port));
  } else {
    process.stdout.write(`ready:${port}\n`);
  }
}

main().catch((err) => {
  process.stderr.write(`Failed to start: ${err.message}\n`);
  process.exit(1);
});
