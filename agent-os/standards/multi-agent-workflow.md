# Multi-Agent Workflow Standard

## Roles

- Product Owner: converts stakeholder intent into prioritized candidate stories that are ready for triad review.
- Domain Analyst: captures domain behavior, hardware/service/data-flow assumptions, contracts, and edge cases.
- User Experience: shapes user-facing workflows, visibility, accessibility, and operational clarity.
- Coordinator Architect: owns implementation planning, source boundaries, worktrees, integration flow, and safety/security requirements.
- Feature Engineer: implements scoped changes and validates them.
- Reviewer Integration: reviews correctness, contracts, validation evidence, integration risk, and release readiness.

## Readiness

A story should not move to implementation until it has:

- a clear behavior goal and acceptance criteria
- affected projects and shared contracts identified
- required Domain Analyst or SME input completed or scheduled
- validation expectations, including hardware/simulator requirements
- known risks and non-goals

## Flow

1. Product Owner clarifies the goal, candidate stories, acceptance criteria, and priority.
2. Product Owner routes every ready candidate story to Coordinator Architect, Domain Analyst, and User Experience before implementation.
3. Coordinator Architect, Domain Analyst, and User Experience decide whether the candidate needs more stories, story splitting, updated acceptance criteria, domain/SME work, UX clarification, or contract-first planning.
4. Once that triad agrees the story is development-ready, Coordinator Architect defines source ownership, branch/worktree plan, integration plan, and validation matrix.
5. Feature Engineers implement only stories that have been marked development-ready and assigned in scoped worktrees.
6. Reviewer Integration reviews handoffs, runs or assesses validation, and gives go/no-go.
7. Coordinator integrates completed work and records remaining risks.

## Story State Meaning

- `Ready`: ready for Coordinator Architect, Domain Analyst, and User Experience triad review.
- `Development-ready`: triad reviewed; source ownership, validation expectations, and role handoff are clear enough to send to Feature Engineering.
- `Active`: a role is currently shaping, implementing, reviewing, or integrating the story.
- `Review`: implementation or analysis is ready for Reviewer Integration or project-owner review.
- `Done`: accepted, merged where applicable, and no immediate follow-up is required.

Do not send a merely `Ready` story directly to Feature Engineering. Feature Engineering starts only after the triad either confirms the current story or updates/splits it and marks the resulting work development-ready.

Agents update `agent-os/product/status-board.md` at each state change so the main session can relay cross-agent progress to the user-visible chat.

## Handoffs

Every implementation handoff should include:

1. Behavior changed
2. Files and projects changed
3. Validation commands and outcomes
4. Contract, hardware, safety, and security notes
5. Risks and follow-up tasks

## Parallelism

Optimize for useful unblocked work without creating conflicts in shared contracts, props, service settings, generated code, hardware interfaces, or algorithm/data models.

Split a blocking story across multiple agents only when Product Owner, Domain Analyst, and Coordinator have defined the shared contract and source ownership clearly enough for independent implementation.
