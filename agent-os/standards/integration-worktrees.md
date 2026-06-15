# Integration Worktrees Standard

## Purpose

Define the default branch, worktree, ownership, and integration rules for running multiple agents against the TripleQuadUI repository.

The Coordinator Architect owns these rules during a delivery batch. The Coordinator may change naming, branch topology, file ownership, or parallel story limits when doing so improves integration safety or delivery speed. Any change must be written into the implementation plan before Feature Engineers start work.

## Worktree Naming

Use one worktree per active agent branch.

Default pattern:

```text
C:/Git/Commercial/MrmETDSpec/TripleQuadUI-<scope>
```

Examples:

```text
C:/Git/Commercial/MrmETDSpec/TripleQuadUI-hardware-service
C:/Git/Commercial/MrmETDSpec/TripleQuadUI-analyzer-ui
C:/Git/Commercial/MrmETDSpec/TripleQuadUI-integration
C:/Git/Commercial/MrmETDSpec/TripleQuadUI-review
```

Rules:

- Keep the canonical checkout at `C:/Git/Commercial/MrmETDSpec/source/TripleQuadUI`.
- Do not run multiple coding agents in the same worktree.
- Do not use the same checked-out branch in more than one active coding worktree.
- Use short, story-oriented names that match the branch purpose.
- The Coordinator may choose a different naming scheme for a batch, but must document it in the execution plan.

## Branch Naming

Use branch names that show the work type, feature, and agent scope.

Default patterns:

```text
feature/<feature-slug>
feature/<feature-slug>-<scope>
integration/<feature-slug>
integration/<batch-slug>
review/<feature-or-batch-slug>
docs/<topic-slug>
fix/<issue-slug>
```

Rules:

- Start feature and fix branches from `master`.
- Use one branch per Feature Engineer worktree.
- Use an integration branch for combining related agent work.
- Do not commit unrelated stories to the same feature branch.
- Prefer feature-scoped branches over project-scoped branches unless the story is truly project-local.
- Do not merge to `master`; notify the project owner when the branch is ready for review and manual merge.

## File Ownership Claims

Before implementation starts, the Coordinator assigns expected ownership.

Ownership claim format:

```text
Story:
Agent:
Branch:
Worktree:
Primary paths:
Shared paths:
Contract files:
Do-not-touch paths:
Validation:
```

Rules:

- Primary paths are owned by one Feature Engineer for the story.
- Shared paths require explicit coordination before edits.
- Contract files require Coordinator visibility and Reviewer Integration validation.
- Package props, appsettings, launch settings, proto contracts, generated code, hardware interfaces, algorithm models, and shared data models are treated as shared unless assigned otherwise.
- If an agent discovers it must edit an unclaimed shared path, it should stop and ask the Coordinator to update the ownership plan.

## Parallel Story Limits

Default starting limit:

```text
1 Product Owner
1 Domain Analyst
1 Coordinator Architect
2 Feature Engineers
1 Reviewer Integration
```

Rules:

- Prefer one vertical Feature Engineer per ready story.
- Keep at least one Reviewer Integration capacity slot for every 2 active Feature Engineers.
- Reduce parallelism when stories touch shared contracts, package config, hardware interfaces, algorithms, appsettings, or the same source files.
- Increase parallelism only after the previous batch merged with low conflict, low rework, and passing validation.
- Blocking stories should be completed before dependent stories unless the contract is stable enough for parallel work.

The Coordinator owns the active parallel story limit for each batch and may change it based on conflict rate, review backlog, test runtime, hardware availability, and integration risk.
