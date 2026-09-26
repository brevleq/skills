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

1. Copy the template: `cp -r template skills/<skill-name>` (Windows: `Copy-Item -Recurse template skills\<skill-name>`)
2. Edit `skills/<skill-name>/SKILL.md`:
   - `name` must match the folder name (lowercase, digits, hyphens).
   - `description` says what the skill does **and when to use it** — it's what the model reads to decide whether to load the skill. Keep it on one line and don't use `: ` (colon followed by a space) inside it, because YAML treats that as a nested key. If you need one, wrap the whole value in double quotes.
3. Delete any of `scripts/`, `references/`, `assets/` you don't need.
4. Register it: `skills/create-skill/scripts/register.sh <skill-name>` (Windows: `powershell -ExecutionPolicy Bypass -File skills\create-skill\scripts\register.ps1 <skill-name>`)
5. Add the skill to the index below.

When Claude creates a skill here, it follows the [create-skill](skills/create-skill/SKILL.md) skill, which does all of these steps.

## Using the skills

- **Personal, for all installed agents:** run the register script for your OS. It validates every skill and links it into the skills folder of each agent installed on the machine: Claude Code, GitHub Copilot and Devin for Terminal. Agents that aren't installed are skipped, so the same command works on any machine.
  - macOS / Linux: `skills/create-skill/scripts/register.sh --all`
  - Windows (PowerShell): `powershell -ExecutionPolicy Bypass -File skills\create-skill\scripts\register.ps1 -All`. It creates directory junctions, which need no administrator rights. The links survive restarts. Run it again after adding a skill or installing a new agent, or use `register.sh <skill-name>` for a single skill.
- **Claude Code (project):** copy or symlink into `<project>/.claude/skills/`
- **Claude apps / API:** zip the skill folder and upload it
- **GitHub Copilot (project):** copy into `<project>/.github/skills/` (Copilot also reads `.claude/skills/` and `.agents/skills/`)
- **Devin (cloud):** commit the skill to `<repo>/.agents/skills/` in the repository Devin works on

## Index

| Skill | Description |
|-------|-------------|
| [create-skill](skills/create-skill/SKILL.md) | Creates a skill in this repository from the template, validates it and registers it right away in every installed agent (Claude Code, GitHub Copilot, Devin for Terminal) |
| [incremental-development](skills/incremental-development/SKILL.md) | Any language: plans a feature as small tasks (at most 4 files each) with approval stops. Test first per task, constants and models before logic, clean code rules |
| [java-unit-tests](skills/java-unit-tests/SKILL.md) | JUnit 5 + Mockito + AssertJ unit tests in two phases reviewed by a developer: failing skeletons first, then the implementation |
| [java-test-helpers](skills/java-test-helpers/SKILL.md) | Test Data Builder helpers (`aCustomer().withStatus(DISABLED).build()`) with complete, valid objects built from random values and preferred defaults |
