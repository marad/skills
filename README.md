# marad/skills

Personal Claude Code skills.

## Skills

- **`excavate/`** — Top-down, layer-by-layer feature development. Annotated module diagram → signatures-only stubs → signature-fit review → tests → bodies. Cold-context subagents enforce independence between design and verification.
- **`chisel/`** — Lightweight cousin of excavate for changes that fit in 1–3 files. Same discipline (no silent load-bearing decisions, contracts before bodies, tests before bodies, self-review), no formal artifacts.

## Install

Clone and symlink the skills you want into `~/.claude/skills/`:

```bash
git clone https://github.com/marad/skills ~/dev-personal/skills
ln -s ~/dev-personal/skills/excavate ~/.claude/skills/excavate
ln -s ~/dev-personal/skills/chisel   ~/.claude/skills/chisel
```

Skills are discovered on the next Claude Code session.
