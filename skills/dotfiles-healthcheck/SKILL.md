---
description: Check and fix dotfiles installation — settings.json, shell profile, and dependencies
---

Run a healthcheck on the local dotfiles setup. For each check, report pass/fail and fix any failures.

## Checks

### 1. Shell profile sources dotfiles

Verify `~/.bash_profile` sources `bash_profile.dotfiles` from the dotfiles repo. The dotfiles repo is at `${CLAUDE_PLUGIN_ROOT}`.

Expected: `~/.bash_profile` contains a `source` line pointing to `${CLAUDE_PLUGIN_ROOT}/bash_profile.dotfiles`.

Fix: append the source line to `~/.bash_profile`.

### 2. Claude Code status line configured

Verify `~/.claude/settings.json` contains:

```json
"statusLine": {
  "type": "command",
  "command": "claude-statusline"
}
```

Fix: read the existing `~/.claude/settings.json`, merge in the statusLine key (preserving all other settings), and write it back. Create the file with just this key if it doesn't exist.

### 3. Dependencies available

Check that these commands exist on PATH:

- `jq` (used by claude-statusline)
- `python3` (used by `c` wrapper for path decoding)

Report missing ones but don't attempt to install them — just note what's needed.

### 4. Scripts on PATH

Verify that `${CLAUDE_PLUGIN_ROOT}/src/scripts/` is on `$PATH` (it should be if check 1 passes). Confirm that `c` and `claude-statusline` are findable via `which`.

## Output

Print a summary like:

```
dotfiles healthcheck:
  [pass] shell profile
  [pass] claude status line
  [FAIL] dependencies: missing jq
  [pass] scripts on PATH
```

Then fix any failures that have a fix defined above.
