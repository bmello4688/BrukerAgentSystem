# TripleQuadUI Agents (Codex)

This OpenClaw workspace is for Bruker Detection's TripleQuadUI local desktop application. The agent system stays local and outside the Bruker Detection Git repo.

## Project Context

- Agent system root: `C:/Git/Commercial/MrmETDSpec`
- Application Git repo root: `C:/Git/Commercial/MrmETDSpec/source/TripleQuadUI`
- Legacy application reference: `C:/Git/DHS-GUI`
- Primary build entry point: `source/TripleQuadUI/MrmEtdMassSpecAnalyzer/MrmEtdMassSpecAnalyzer.slnx`
- Remote: `http://nbbil03-build.bdet.local/Git/Commercial/TripleQuadUI.git`
- Product context: `agent-os/product/`
- Standards: `agent-os/standards/`
- Shared status board: `agent-os/product/status-board.md`
- Specs: `agent-os/specs/`
- Role prompts: `.orchestration/agents/`

## Roles

1. Product Owner
2. Domain Analyst
3. User Experience
4. Coordinator Architect
5. Feature Engineer
6. Reviewer Integration

Use `.orchestration/agents/` as the source of truth for role-specific behavior.

## Operating Rules

- Work on application code inside `source/TripleQuadUI` unless the user names another path.
- Check `git status --short --branch` in `source/TripleQuadUI` before code edits.
- Do not commit agent system files to the Bruker Detection repo.
- Preserve unrelated local changes.
- Use feature branches from `master`; the project owner reviews and manually merges accepted branches to `master`.
- Notify the configured Discord channel when a feature branch is ready for review and manual merge.
- Update `agent-os/product/status-board.md` whenever work starts, state changes, blockers appear, validation completes, or handoff/review/done status changes. Use `YYYY-MM-DD HH:MM TZ - Agent Name - State: concise status` so chat relays can report `[Agent Name] - status`.
- Run builds and tests freely.
- Treat TripleQuadUI as a rewrite of `C:/Git/DHS-GUI`; compare legacy behavior when requirements are unclear.
- Treat this as a local Uno/.NET 9 desktop application with ASP.NET-style local microservices.
- Limit hardware/instrument behavior changes to explicit feature scope or documented bug fixes for owner review.
- Treat company IP, hardware behavior, internal infrastructure, and sensitive data as confidential.
- Record validation limits caused by hardware, simulator, licenses, credentials, VPN, or internal services.

## High-Coordination Areas

- `Directory.Build.props`, `Directory.Build.targets`, `Directory.Packages.props`, `global.json`, and `.gitmodules`
- proto/gRPC contracts and generated code
- appsettings and launch settings
- hardware interfaces, instrument communication, and simulator behavior
- shared data-service models and algorithm libraries

## Handoff Format

1. Behavior changed
2. Files and projects changed
3. Validation commands and outcomes
4. Contract, hardware, safety, and security notes
5. Risks and follow-up tasks
