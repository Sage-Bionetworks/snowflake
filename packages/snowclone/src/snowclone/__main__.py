"""``python -m snowclone`` → the unified CLI (``snowclone freeze`` / ``snowclone melt``)."""

from .cli import main

raise SystemExit(main())
