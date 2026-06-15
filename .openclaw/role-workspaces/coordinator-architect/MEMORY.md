# TripleQuadUI OpenClaw Memory

## Setup

- OpenClaw is intended to operate from `C:\Git\Commercial\MrmETDSpec` while editing application code under `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`.
- Role prompts live under `.orchestration\agents\`.
- OpenClaw-local workspace notes live under `.openclaw\workspace\`.
- Agent system files should stay out of the Bruker Detection Git repo.
- Dashboard-visible role agents are created with `.openclaw\add-triplequadui-openclaw-agents.ps1`.
- The role workspace generator includes Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, and Reviewer Integration agents.
- Branch flow is feature branches from `master`; Brian reviews and manually merges accepted branches to `master`.
- Notify the active Discord `#brukerdev` channel when a feature branch is ready for review and manual merge.
- Agents may run builds and tests freely. Primary build entry point is `source\TripleQuadUI\MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`.
- TripleQuadUI is a rewrite of the legacy app at `C:\Git\DHS-GUI`.
- Hardware/instrument changes are limited to explicit feature scope or documented bug fixes for owner review.

## Operating Notes

- Keep OpenClaw-local notes and markers out of product docs unless they are sanitized durable project context.
- Use `agent-os/product/agent-continuity.md` for portable project memory.
- Keep any mention of OpenClaw, Agent OS, orchestration, or agent usage out of the Bruker Detection Git repo.
