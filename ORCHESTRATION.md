# TripleQuadUI Instructions (Orchestration + Codex)

This local workspace is configured for orchestration workflows using Codex/OpenClaw agents. The agent system is intentionally outside the Bruker Detection Git repo.

## Project Context

- Agent system root: `C:/Git/Commercial/MrmETDSpec`
- Application Git repo root: `C:/Git/Commercial/MrmETDSpec/source/TripleQuadUI`
- Legacy application reference: `C:/Git/DHS-GUI`
- Primary build entry point: `source/TripleQuadUI/MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx`
- Product context: `agent-os/product/`
- Specs: `agent-os/specs/`
- Standards: `agent-os/standards/`
- Application source: repo folders under `source/TripleQuadUI`, such as `MrmEtdMassSpecAnalyzer/`, `HardwareLayer/`, `CoreLogicLayer/`, `CommonLibraries/`, and `CommonLibraries.Uno/`

## Standard Roles

1. Product Owner
2. Domain Analyst
3. User Experience
4. Coordinator Architect
5. Feature Engineer
6. Reviewer Integration

Use role-specific prompts from `.orchestration/agents/` when delegating specialized work.

## Role Flow

1. Product Owner works with the stakeholder to convert intent into prioritized stories, acceptance criteria, risk notes, and dependency order.
2. Domain Analyst captures domain behavior, instrument/hardware assumptions, service contracts, data flows, and edge cases, then turns them into implementation-ready notes.
3. Coordinator Architect turns approved stories and domain notes into execution plans, worktree/branch assignments, source boundaries, integration flow, and safety-sensitive technical requirements.
4. Feature Engineer agents implement assigned stories across the necessary projects.
5. Reviewer Integration validates review-ready branch behavior, contract compatibility, Coordinator-defined safety/security requirements, and release readiness.

## Operating Rules

- Follow `agent-os/standards/multi-agent-workflow.md`.
- Follow `agent-os/standards/source-control.md` for branch and working-state discipline.
- Follow `agent-os/standards/integration-worktrees.md` for worktree, branch, ownership, and integration flow.
- Follow `agent-os/standards/testing.md` for validation evidence.
- Follow `agent-os/standards/backend/api.md` for service, API, and gRPC changes.
- Do not commit the agent system files to the Bruker Detection repo.
- For notifications, read `.openclaw/notification-routing.json` and use its `defaultNotificationTarget` instead of hard-coding contact details.
- Notify the active Discord channel when a feature branch is ready for project-owner code review and manual merge to `master`.

## Required Handoff Format

1. Behavior changed
2. Files and projects changed
3. Validation commands and outcomes
4. Contract, hardware, safety, and security notes
5. Risks and follow-up tasks
