#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.claude/skills"

mkdir -p "$target"

for skill_md in "$repo"/*/SKILL.md; do
  src="$(dirname "$skill_md")"
  name="$(basename "$src")"
  link="$target/$name"

  if [ -L "$link" ]; then
    current="$(readlink "$link")"
    if [ "$current" = "$src" ]; then
      echo "ok       $name"
    else
      echo "conflict $name -> $current (not ours, skipped)"
    fi
  elif [ -e "$link" ]; then
    echo "conflict $name (real file/directory, skipped)"
  else
    ln -s "$src" "$link"
    echo "linked   $name"
  fi
done

echo
echo "Skills are discovered on the next Claude Code session."
