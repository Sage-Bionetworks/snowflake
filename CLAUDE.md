@AGENTS.md
This repository uses `AGENTS.md` as the canonical source for directory-scoped agent instructions.

For Claude compatibility, each directory that contains an `AGENTS.md` file should also include a `CLAUDE.md` shim with contents:

`@AGENTS.md`

When looking for directory-scoped memory/instruction files:
- If `CLAUDE.md` exists in a directory, follow it and resolve any `@AGENTS.md` reference in that same directory.
- Treat the referenced `AGENTS.md` as the authoritative instruction content.
- Keep `CLAUDE.md` shims minimal; put substantive instructions in `AGENTS.md`.

In short: use per-directory `CLAUDE.md` shims for discovery and `AGENTS.md` for actual instructions.