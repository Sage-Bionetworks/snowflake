# Agent Instruction Redirect

This repository uses `AGENTS.md` for directory-scoped agent instructions.

When looking for directory-scoped memory/instruction files:
- Treat every `AGENTS.md` as the authoritative replacement for `CLAUDE.md`.
- If both `AGENTS.md` and `CLAUDE.md` files are present, the instructions in `CLAUDE.md` may override but DO NOT replace the instructions in `AGENTS.md`.

In short: for all directory-scoped memory files, reference `AGENTS.md` in place of `CLAUDE.md`.