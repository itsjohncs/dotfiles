---
description: Create a new skill in the dotfiles plugin — use when asked to add a skill, command, or slash command to the dotfiles plugin
---

# Add Skill to Dotfiles Plugin

Create a new skill in `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/SKILL.md`.

## SKILL.md format

```markdown
---
description: <what it does AND when to trigger — this drives skill discovery>
---

<instructions for the agent when invoked>
```

## Conventions

- **Skill directory**: `${CLAUDE_PLUGIN_ROOT}/skills/<kebab-case-name>/`
- **Helper scripts**: `${CLAUDE_PLUGIN_ROOT}/src/scripts/` (automatically on PATH via dotfiles)
- **Description**: Be specific about both purpose and trigger conditions. This is what Claude Code uses to decide when to suggest the skill.
- Reference existing skills in `${CLAUDE_PLUGIN_ROOT}/skills/` for patterns.

## Process

1. Clarify what the skill should do if not obvious from context
2. Create the skill directory and SKILL.md
3. If the skill needs helper scripts, create them in `${CLAUDE_PLUGIN_ROOT}/src/scripts/` and make them executable
4. Run linters on any new scripts: `uvx pre-commit run --files <files>`
