# Tool preferences

- Never use ad-hoc `python3`/`node`/`ruby` heredocs, `sed -i`, or one-off shell scripts to edit or search files. Use the Edit, Write, Read, and Grep tools instead — they don't carry the same permission/approval overhead as arbitrary shell execution, and they're just as capable for text edits, find/replace, and searches.
- Only drop into Bash for things those tools genuinely can't do: running tests/builds, git, gh, docker, package managers, etc.
