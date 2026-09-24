# Skills

A collection of skills for LLM agents (Claude Code, Claude apps, Agent SDK, and other tools that support the Agent Skills format).

## Layout

```
.
├── skills/              # one folder per skill
│   └── <skill-name>/
│       ├── SKILL.md     # required: frontmatter + instructions
│       ├── scripts/     # optional: executable helpers the skill calls
│       ├── references/  # optional: docs loaded on demand
│       └── assets/      # optional: templates, images, other files used in output
└── template/            # starting point for new skills
```

## Adding a skill

1. Copy the template: `cp -r template skills/<skill-name>`
2. Edit `skills/<skill-name>/SKILL.md`:
   - `name` must match the folder name (lowercase, digits, hyphens).
   - `description` says what the skill does **and when to use it** — it's what the model reads to decide whether to load the skill.
3. Delete any of `scripts/`, `references/`, `assets/` you don't need.
4. Add the skill to the index below.

## Using the skills

- **Claude Code (personal):** symlink a skill into `~/.claude/skills/`, e.g. `ln -s "$PWD/skills/<skill-name>" ~/.claude/skills/`
- **Claude Code (project):** copy or symlink into `<project>/.claude/skills/`
- **Claude apps / API:** zip the skill folder and upload it

## Index

| Skill | Description |
|-------|-------------|
| _none yet_ | |
