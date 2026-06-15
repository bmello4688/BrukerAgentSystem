# AGENTS.md - TripleQuadUI Agent Workspace

This workspace is for development of Bruker Detection's TripleQuadUI / MrmETD local desktop mass spectrometry application.

## Repository

- Agent system root: `C:\Git\Commercial\MrmETDSpec`
- Application Git repo root: `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`
- Legacy application reference: `C:\Git\DHS-GUI`
- Remote: `http://nbbil03-build.bdet.local/Git/Commercial/TripleQuadUI.git`
- Company context: Bruker Detection
- Agent OS context: `agent-os/`
- Role prompts: `.orchestration/agents/`
- OpenClaw project workspace: `.openclaw/workspace/`

## Source Layout

- `MrmEtdMassSpecAnalyzer/` - primary analyzer UI and microservice host.
- `HardwareLayer/` - instrument, simulator, MS workstation, and hardware service components.
- `CoreLogicLayer/` - substance analyzer core client/service/models.
- `CommonLibraries/` - shared data service, algorithms, logging, Python interop, and related libraries.
- `CommonLibraries.Uno/` - shared Uno/common platform libraries.
- `LaunchApplicationAndMicroServices/` and `InstallEmbeddedPython/` - local launch and embedded Python support.

## Working Rules

- Keep this agent system outside the Bruker Detection Git worktree. Do not add `AGENTS.md`, `ORCHESTRATION.md`, `agent-os/`, `.orchestration/`, or `.openclaw/` to `source\TripleQuadUI`.
- Work on application code inside `source\TripleQuadUI`.
- Always check `git status --short --branch` in `source\TripleQuadUI` before code edits.
- Do not overwrite unrelated local changes. This checkout may already contain user or company work.
- Keep code changes scoped to the affected project, service, or library.
- Prefer existing .NET, Uno, gRPC, StyleCop, and solution patterns over introducing new conventions.
- Treat this as a local Uno/.NET 9 desktop application with ASP.NET-style local microservices.
- Be careful around hardware, instrument communication, simulator behavior, data acquisition, analysis algorithms, and generated/proto contracts.
- Treat TripleQuadUI as a rewrite of the legacy DHS-GUI application with enhanced architecture. Use `C:\Git\DHS-GUI` for behavioral comparison when requested or when domain behavior is unclear.
- Hardware/instrument behavior should preserve legacy-compatible behavior unless the story explicitly authorizes a change or a clear bug is found and documented for review.
- Use feature branches from `master`; never merge to `master`. Notify the project owner in the active Discord channel when a feature branch is ready for code review and manual merge.
- Agents may run local builds and tests freely.
- Treat company IP, instrument details, and customer or lab data as confidential.
- Do not send data outside the machine or company-approved systems without explicit approval.

## Agent System

Use `ORCHESTRATION.md` for the role flow and handoff format.

Use role-specific prompts from `.orchestration/agents/` when delegating specialized work:

1. Product Owner
2. Domain Analyst
3. User Experience
4. Coordinator Architect
5. Feature Engineer
6. Reviewer Integration

Use standards under `agent-os/standards/` for source control, worktrees, testing, story sizing, readiness, and completion.

For cross-agent progress, update `agent-os/product/status-board.md` using `agent-os/standards/status-board.md`. Status updates should identify the agent clearly so chat relays can use `[Agent Name] - status`.

## Validation

Prefer the smallest meaningful validation first:

- Build or test the specific `.csproj` touched.
- Use `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` as the primary solution-level build entry point.
- Run relevant solution-level checks when shared contracts, package props, microservice behavior, or hardware interfaces change.
- Record commands and outcomes in the handoff.

If a command cannot run because required hardware, internal services, licenses, VPN, credentials, or build tools are unavailable, state that clearly and provide the closest completed validation.
