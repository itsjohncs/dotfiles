---
description: Launch and control Playwright browsers — navigate, click, type, screenshot, and more. Use when you need to interact with web pages, test UIs, or scrape content. Each agent gets its own browser instance and chooses headless or headed mode.
---

# Playwright Browser Control

Control browsers via the `pw` command. Each agent launches its own independent browser instance.

## Quick Start

```bash
# Launch a browser (use --headless for background work, omit for visible browser)
PORT=$(pw launch --headless)

# Navigate and interact
pw $PORT browser_navigate '{"url": "https://example.com"}'
pw $PORT browser_snapshot
pw $PORT browser_click '{"ref": "s1e4", "element": "Login button"}'
pw $PORT browser_take_screenshot '{"type": "png"}'

# Always clean up when done
pw $PORT close
```

## Headless vs Headed

- `pw launch --headless` — No visible browser. Use this for most agent work.
- `pw launch` — Visible browser window. Use when the user wants to watch or the task requires visual verification.

## Session Management

- `pw launch [--headless]` — Start a new browser. Prints the port number. Auto-cleans stale sessions from previous runs.
- `pw <port> close` — Close the browser and shut down the server. **Always do this when done.**
- `pw cleanup` — Kill all stale browser sessions.
- `pw install` — Install the Chromium binary (run if you get "browser not installed" errors).

## Calling Tools

```bash
pw <port> <tool_name> '<json_args>'
```

Tool names and arguments match the Playwright MCP exactly. The JSON argument is optional and defaults to `{}`.

## Navigation

| Command                 | Arguments          |
| ----------------------- | ------------------ |
| `browser_navigate`      | `{"url": "<url>"}` |
| `browser_navigate_back` | (none)             |

## Page Inspection

| Command                    | Arguments                        | Notes                                                                                |
| -------------------------- | -------------------------------- | ------------------------------------------------------------------------------------ |
| `browser_snapshot`         | `{}` or `{"filename": "<path>"}` | Accessibility tree with refs. **Always do this before interacting.**                 |
| `browser_take_screenshot`  | `{"type": "png"}`                | Also: `"filename"`, `"fullPage": true`, `"ref"` + `"element"` for element screenshot |
| `browser_console_messages` | `{"level": "error"}`             | Levels: error, warning, info, debug                                                  |
| `browser_network_requests` | `{"includeStatic": false}`       | Network log since page load                                                          |

### Snapshot Output

`browser_snapshot` returns an accessibility tree with ref IDs:

```
- document [ref=s1e2]
  - heading "Page Title" [ref=s1e3]
  - textbox "Search" [ref=s1e4]
  - button "Submit" [ref=s1e5]
```

Use these `ref` values in interaction commands.

## Interaction

All interaction commands use `ref` values from the most recent `browser_snapshot`.

| Command                 | Arguments                                                                                                                                                       |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `browser_click`         | `{"ref": "<ref>", "element": "<description>"}` Optional: `"button"` (left/right/middle), `"doubleClick": true`, `"modifiers": ["Alt","Control","Meta","Shift"]` |
| `browser_type`          | `{"ref": "<ref>", "text": "<text>"}` Optional: `"slowly": true`, `"submit": true`                                                                               |
| `browser_hover`         | `{"ref": "<ref>", "element": "<description>"}`                                                                                                                  |
| `browser_drag`          | `{"startRef": "<ref>", "startElement": "...", "endRef": "<ref>", "endElement": "..."}`                                                                          |
| `browser_select_option` | `{"ref": "<ref>", "values": ["option1"]}`                                                                                                                       |
| `browser_press_key`     | `{"key": "Enter"}` Keys: Enter, Tab, Escape, ArrowLeft, ArrowRight, ArrowUp, ArrowDown, etc.                                                                    |
| `browser_fill_form`     | `{"fields": [{"ref": "<ref>", "name": "<label>", "type": "textbox", "value": "<text>"}]}` Types: textbox, checkbox, radio, combobox, slider                     |
| `browser_file_upload`   | `{"paths": ["/absolute/path/to/file"]}`                                                                                                                         |
| `browser_handle_dialog` | `{"accept": true}` Optional: `"promptText": "..."`                                                                                                              |

## Tabs

| Command        | Arguments                                                  |
| -------------- | ---------------------------------------------------------- |
| `browser_tabs` | `{"action": "list"}`                                       |
| `browser_tabs` | `{"action": "new"}`                                        |
| `browser_tabs` | `{"action": "select", "index": 0}`                         |
| `browser_tabs` | `{"action": "close"}` or `{"action": "close", "index": 1}` |

## Advanced

| Command            | Arguments                                                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `browser_evaluate` | `{"function": "() => document.title"}` With element: `{"function": "(el) => el.textContent", "ref": "<ref>", "element": "..."}` |
| `browser_run_code` | `{"code": "async (page) => { await page.click('#btn'); return await page.title(); }"}`                                          |
| `browser_resize`   | `{"width": 1280, "height": 800}`                                                                                                |
| `browser_wait_for` | `{"text": "Loaded"}` or `{"textGone": "Loading..."}` or `{"time": 3}`                                                           |
| `browser_install`  | (none) — Install browser binary                                                                                                 |

## Workflow

1. Launch with `pw launch` (choose headless/headed)
2. Navigate to the target URL
3. **Snapshot** to see page structure and get refs
4. Interact using refs from the snapshot
5. **Snapshot again** after interactions — old refs go stale
6. Screenshot to visually verify if needed
7. **Always close** with `pw <port> close`

## Tips

- Prefer `browser_snapshot` over screenshots for understanding page structure — it gives actionable refs.
- After any interaction that changes the page, take a new snapshot.
- Use `browser_evaluate` to read page state not in the accessibility tree.
- Use `browser_run_code` as an escape hatch for complex multi-step Playwright scripting.
- If the browser isn't installed, run `pw install` first.
