---
name: create-skill
description: Creates a new skill in this skills repository and registers it right away in every installed agent (Claude Code, GitHub Copilot, Devin for Terminal), so it's available in every session on that machine. Also registers existing skills and fixes broken links. Use when asked to create, add, scaffold or register a skill in this repository.
---

# Create Skill

Every skill in this repository must be **registered** as soon as it's created: linked from each agent's skills folder to `skills/<skill-name>` in this repository.

| Agent | macOS / Linux | Windows | Registered |
|-------|---------------|---------|------------|
| Claude Code | `~/.claude/skills` | `%USERPROFILE%\.claude\skills` | When the `claude` CLI or the `.claude` folder is found |
| GitHub Copilot (CLI, VS Code) | `~/.copilot/skills` | `%USERPROFILE%\.copilot\skills` | When the `copilot` CLI, the `.copilot` folder or the VS Code Copilot extension is found |
| Devin for Terminal | `~/.config/devin/skills` | `%APPDATA%\devin\skills` | When the `devin` CLI or Devin's config folder is found |

There's one script per platform. Use the one for the OS you're running on:

| Platform | Script | Link type |
|----------|--------|-----------|
| macOS, Linux | `scripts/register.sh` | Symbolic link |
| Windows | `scripts/register.ps1` | Directory junction, which needs no administrator rights or Developer Mode |

`register.sh` refuses to run in Git Bash or Cygwin on Windows, because `ln -s` makes copies there instead of links.

The links survive restarts, and edits in the repository show up in every agent without registering again. Devin's cloud agent can't use personal skills. It reads skills committed to the repository it works on (`.agents/skills/`), so this script doesn't cover it.

A skill isn't done until the register script has succeeded for it.

## Steps

1. **Pick the name.** Lowercase letters, digits and hyphens (e.g. `java-unit-tests`). It must not exist yet in `skills/` or in any agent's skills folder.
2. **Copy the template** from the repository root:
   ```sh
   cp -R template skills/<skill-name>                          # macOS / Linux
   Copy-Item -Recurse template skills\<skill-name>              # Windows (PowerShell)
   ```
3. **Write `SKILL.md`:**
   - `name` must match the folder name exactly.
   - `description` says what the skill does **and when to use it**, since it's what the model reads to decide whether to load the skill. Keep it on one line, and don't use `: ` (a colon followed by a space) in it, because YAML reads that as a nested key.
   - Keep the body focused on instructions. Move long reference material and examples into `references/`, and executable helpers into `scripts/`.
   - Follow the style of the existing skills in `skills/`.
4. **Remove what isn't used:** delete the `scripts/`, `references/` or `assets/` folders the skill doesn't need, and the `.gitkeep` files in the ones it does.
5. **Register it:**
   ```sh
   skills/create-skill/scripts/register.sh <skill-name>                                         # macOS / Linux
   powershell -ExecutionPolicy Bypass -File skills\create-skill\scripts\register.ps1 <skill-name>   # Windows
   ```
   `-ExecutionPolicy Bypass` applies only to that command. It's needed because Windows blocks unsigned scripts by default.
   The script checks that `SKILL.md` exists, that `name` matches the folder, and that `description` is present and valid YAML. It then links the skill into the folder of every installed agent, and verifies each link. It prints `SKIP` for agents that aren't installed, which is fine, since the repository is used on machines with different agents. It fails if no supported agent is installed. If it reports an error, fix the skill and run it again. **Don't finish until it prints `OK` for every installed agent.**
6. **Add the skill to the index** in `README.md`: one row with a link to its `SKILL.md` and a one-line description.
7. **Report** the skill's files, the agents it was registered in, and the agents that were skipped. The skill is available in new sessions, and a session that's already running may need a restart to load it.

Don't commit. The user reviews and commits.

## Other uses

- **Register every skill,** e.g. on a new machine, after moving the repository, or after installing another agent:
  ```sh
  skills/create-skill/scripts/register.sh --all                                         # macOS / Linux
  powershell -ExecutionPolicy Bypass -File skills\create-skill\scripts\register.ps1 -All   # Windows
  ```
- **Renaming a skill:** rename the folder and `name`, remove the old link from every agent's skills folder (`rm ~/.claude/skills/<old-name>` on macOS / Linux, `cmd /c rmdir "%USERPROFILE%\.claude\skills\<old-name>"` on Windows; both delete only the link), register the new name, and update the README.
- **Deleting a skill:** remove the links from every agent's skills folder, remove the skill's folder, and remove the README row. Ask the user before deleting.

## Safety

- The script **never overwrites** a real folder in an agent's skills folder. If a folder with the same name already exists there and isn't a link, it stops with an error. Tell the user, and don't remove that folder yourself.
- Don't touch anything else in the agents' skills folders, such as `~/.claude/skills/synced`.
- On Windows, never delete a junction with `Remove-Item -Recurse` or Explorer's delete with contents. Older PowerShell versions can follow the junction and delete the skill's files in the repository. Use `cmd /c rmdir <link>`.
- To test a script without touching your real folders, point it at a fake home folder: `HOME=/tmp/fake-home skills/create-skill/scripts/register.sh --all` on macOS / Linux, or set `$env:USERPROFILE` and `$env:APPDATA` to a temporary folder before running `register.ps1` on Windows.
