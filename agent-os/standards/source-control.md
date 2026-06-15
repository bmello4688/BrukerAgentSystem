# Source Control Standard

## Repository

The Bruker Detection TripleQuadUI repo is the source repository for application code only. The agent system stays local at `C:\Git\Commercial\MrmETDSpec` and should not be checked in.

Commit Bruker repository changes only when application source changes.

Do not add `AGENTS.md`, `ORCHESTRATION.md`, `agent-os/`, `.orchestration/`, or `.openclaw/` to the Bruker Detection repo.

## Branching

Start from `master` and use one branch per coherent feature or fix:

```powershell
git checkout master
git pull
git checkout -b feature/<feature-name>
```

Use `fix/<issue-slug>` or `docs/<topic-slug>` when that better describes the work.

Agents must not merge to `master`. When a branch is ready, notify the project owner in the configured Discord channel with:

- branch name
- summary of behavior changed
- validation performed
- known risks or review focus

The project owner performs code review and manually merges accepted branches to `master`. If review is rejected, fix the same feature branch or a replacement feature branch and request review again.

## Working State

Before changing code:

```powershell
git status --short --branch
```

Before handoff:

```powershell
git status --short
```

Do not mix unrelated features in one branch. If two agents need the same files, coordinate through the feature spec or an integration branch.

Treat these as shared/high-coordination areas:

- `Directory.Build.props`
- `Directory.Build.targets`
- `Directory.Packages.props`
- `global.json`
- `.gitmodules`
- proto/gRPC contracts
- generated code
- appsettings and launch settings
- hardware interfaces and simulator contracts
- shared algorithm/data-service models

Do not mention agent usage, OpenClaw, orchestration, or Agent OS in commits, commit messages, branch names, PR titles/descriptions, release notes, or files inside the Bruker Detection repo.
