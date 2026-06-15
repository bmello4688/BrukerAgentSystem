# Shared Status Board Standard

The shared status board is `agent-os/product/status-board.md`.

## Required Updates

Agents must update the board whenever they:

- accept or start a task
- change state between Ready, Active, Blocked, Review, and Done
- claim or release source ownership
- discover a blocker, dependency, or cross-agent conflict
- complete validation or produce handoff evidence
- finish a task or leave follow-up work

## Entry Content

Each status update should include:

- timestamp with timezone
- agent or role name
- state
- task or story name
- branch/worktree when code is involved
- claimed files or source area
- latest validation result
- blocker or next action

Use a line shape that can relay cleanly to chat:

- `YYYY-MM-DD HH:MM TZ - Agent Name - State: concise status`

## Notification Behavior

The main session watches `agent-os/product/status-board.md` and announces meaningful changes back to the user-visible session. Keep board updates readable because they may be printed directly into the chat surface.

When relaying status to chat, use Brian's preferred prefix:

- `[Agent Name] - concise status`

## Privacy

Do not put secrets, credentials, private contact details, raw runtime IDs, customer data, or sensitive transcript excerpts in the board. Link to sanitized project notes when more detail is needed.
