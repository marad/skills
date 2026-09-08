# marad/skills

Personal Claude Code skills.

## Skills

- **`excavate/`** — Top-down, layer-by-layer feature development. Annotated module diagram → signatures-only stubs → signature-fit review → tests → bodies. Cold-context subagents enforce independence between design and verification.
- **`chisel/`** — Lightweight cousin of excavate for changes that fit in 1–3 files. Same discipline (no silent load-bearing decisions, contracts before bodies, tests before bodies, self-review), no formal artifacts.
- **`elicit/`** — Conversational information gathering. When the agent needs several pieces of information from the user, it discusses them one topic at a time — context and opinion first, free-form exchange, agent proposes closing but only the user closes a topic — instead of dumping a list of questions.
- **`review-until-clean/`** — Thin wrapper that runs `/loop /code-review --fix` until there are no material findings left in the diff. Saves re-typing the command.

## Third-party skills

Skills copied from other people's repos, kept here for convenience. Credit and licence belong to the original authors.

- **`bro/`** — Restate the last message in plain language, no jargon. By [Dillon Mulroy](https://github.com/dmmulroy), from [dmmulroy/skills](https://github.com/dmmulroy/skills/blob/main/bro/SKILL.md) (MIT).

## Install

Clone and symlink the skills you want into `~/.claude/skills/`:

```bash
git clone https://github.com/marad/skills ~/dev-personal/skills
ln -s ~/dev-personal/skills/excavate ~/.claude/skills/excavate
ln -s ~/dev-personal/skills/chisel   ~/.claude/skills/chisel
ln -s ~/dev-personal/skills/review-until-clean ~/.claude/skills/review-until-clean
ln -s ~/dev-personal/skills/bro     ~/.claude/skills/bro
```

Skills are discovered on the next Claude Code session.
