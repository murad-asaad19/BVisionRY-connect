
## Environment Notes
- Python command is `py` (NOT `python3` or `python`) — Windows Python launcher
- In bash inline Python, `!=` gets escaped to `\!=` — use `not x == y` instead

Make sure you use rtk before command as instructed in the global CLAUDE.md file
Don't do workaround, make the implementation as clean and reusable as possible.
Use the monitor tool when running the server to save context tokens
Don't re-read file you already read, only when it's failing to edit.
Always make the right design decisions, if you are unsure, always revert to the user.
If there is an implementation from the framework's library, use it and don't implement it your self
Make sure you implement as fast as possible without sacrificing quality, don't worry about token consumption
Don't put work estimation like a human, you are an AI agent without limits.
