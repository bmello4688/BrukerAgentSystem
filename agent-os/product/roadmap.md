# TripleQuadUI Roadmap

## Phase 1: Agent System Foundation

- Keep Agent OS docs outside the Bruker Detection `TripleQuadUI.git` repository.
- Standardize role prompts, feature specs, handoffs, and integration notes.
- Use feature branches from `master`; notify the project owner in Discord when ready for review and manual merge.
- Register all six roles.

## Phase 2: Repository Understanding

- Map project dependencies, service boundaries, and launch workflows.
- Use `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` as the primary solution-level build entry point.
- Compare unclear rewrite behavior against `C:\Git\DHS-GUI`.
- Document hardware, simulator, internal service, credential, and license prerequisites.
- Identify high-risk shared files and generated-contract workflows.

## Phase 3: Feature Delivery Model

- Use Product Owner and Domain Analyst roles to make stories ready before implementation.
- Use Coordinator Architect to assign source boundaries and validation expectations.
- Use Feature Engineer agents for scoped implementation.
- Use Reviewer Integration for contract, hardware/simulator, and release-readiness review.
- Keep hardware/instrument behavior changes behind explicit feature scope or documented bug-fix review.

## Phase 4: Validation Hardening

- Improve focused project-level build/test guidance.
- Add or document simulator and hardware validation paths where practical.
- Preserve useful agent learning in `agent-os/product/agent-continuity.md`.
