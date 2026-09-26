#!/usr/bin/env bash
# Validates skills in this repository and links them into the skills folder of
# every supported agent installed on this machine:
#   Claude Code         ~/.claude/skills        when the claude CLI or ~/.claude exists
#   GitHub Copilot      ~/.copilot/skills       when the copilot CLI, ~/.copilot or the VS Code extension exists
#   Devin for Terminal  ~/.config/devin/skills  when the devin CLI or ~/.config/devin exists
#
# Usage:
#   register.sh <skill-name>...   register the given skills
#   register.sh --all             register every skill in the repository
#
# macOS and Linux only. On Windows, use register.ps1.
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
    echo "ERROR [$1]: $2" >&2
    return 1
}

frontmatter_value() {
    local file="$1" key="$2"
    awk -v key="$key" '
        NR == 1 && $0 != "---" { exit }
        NR > 1 && $0 == "---" { exit }
        NR > 1 && index($0, key ": ") == 1 { print substr($0, length(key) + 3); exit }
    ' "$file"
}

is_quoted() {
    [[ "$1" == \"*\" || "$1" == \'*\' ]]
}

validate() {
    local name="$1" dir="$SKILLS_DIR/$1" file="$SKILLS_DIR/$1/SKILL.md"
    [[ -d "$dir" ]] || fail "$name" "folder $dir not found" || return 1
    [[ -f "$file" ]] || fail "$name" "SKILL.md not found" || return 1
    [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "$name" "folder name must be lowercase letters, digits and hyphens" || return 1

    local fm_name description
    fm_name="$(frontmatter_value "$file" name)"
    description="$(frontmatter_value "$file" description)"
    [[ "$fm_name" == "$name" ]] || fail "$name" "frontmatter name '$fm_name' must match the folder name" || return 1
    [[ -n "$description" ]] || fail "$name" "frontmatter description is missing or not on one line" || return 1
    if ! is_quoted "$description" && [[ "$description" == *": "* ]]; then
        fail "$name" "description contains ': ', which is invalid YAML. Reword it or wrap it in double quotes" || return 1
    fi
}

is_claude_installed() {
    command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]
}

is_copilot_installed() {
    command -v copilot >/dev/null 2>&1 \
        || [[ -d "$HOME/.copilot" ]] \
        || compgen -G "$HOME/.vscode/extensions/github.copilot*" >/dev/null
}

is_devin_installed() {
    command -v devin >/dev/null 2>&1 || [[ -d "$HOME/.config/devin" ]]
}

# Prints "agent|skills-folder" for every installed agent.
installed_targets() {
    if is_claude_installed; then echo "claude|$HOME/.claude/skills"; else echo "SKIP claude (not installed)" >&2; fi
    if is_copilot_installed; then echo "copilot|$HOME/.copilot/skills"; else echo "SKIP copilot (not installed)" >&2; fi
    if is_devin_installed; then echo "devin|$HOME/.config/devin/skills"; else echo "SKIP devin (not installed)" >&2; fi
}

link() {
    local name="$1" agent="$2" target_dir="$3"
    local source="$SKILLS_DIR/$name" link_path="$target_dir/$name"
    if [[ -e "$link_path" && ! -L "$link_path" ]]; then
        fail "$name" "$link_path exists and is not a symlink; not overwriting it" || return 1
    fi
    ln -sfn "$source" "$link_path"
    [[ "$(readlink "$link_path")" == "$source" ]] || fail "$name" "link was not created correctly" || return 1
    echo "OK   $agent: $name -> $source"
}

main() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            echo "ERROR: on Windows, use register.ps1 (ln -s doesn't create real links in Git Bash or Cygwin)" >&2
            exit 1 ;;
    esac
    [[ $# -gt 0 ]] || { echo "Usage: $0 <skill-name>... | --all" >&2; exit 2; }
    local names=("$@")
    if [[ "$1" == "--all" ]]; then
        names=()
        for dir in "$SKILLS_DIR"/*/; do names+=("$(basename "$dir")"); done
    fi

    local targets=() target
    while IFS= read -r target; do targets+=("$target"); done < <(installed_targets)
    if [[ ${#targets[@]} -eq 0 ]]; then
        echo "ERROR: no supported agent (Claude Code, GitHub Copilot, Devin for Terminal) is installed" >&2
        exit 1
    fi

    local failed=0 name
    for name in "${names[@]}"; do
        validate "$name" || { failed=1; continue; }
        for target in "${targets[@]}"; do
            mkdir -p "${target#*|}"
            link "$name" "${target%%|*}" "${target#*|}" || failed=1
        done
    done
    exit "$failed"
}

main "$@"
