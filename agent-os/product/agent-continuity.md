# TripleQuadUI Agent Continuity Notes

These notes preserve portable project context for future agents without storing raw local workspace state, runtime IDs, contact details, credentials, customer data, or sensitive company details.

## Current Known Context

- The agent system belongs in `C:\Git\Commercial\MrmETDSpec`, outside the Bruker Detection Git checkout.
- The application Git repo is `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`.
- The legacy application being rewritten is at `C:\Git\DHS-GUI`.
- The remote is `http://nbbil03-build.bdet.local/Git/Commercial/TripleQuadUI.git`.
- The copied project scaffolding was retargeted on 2026-06-03.
- The repo is .NET 9/Uno/service-heavy and includes a local analyzer desktop UI, ASP.NET-style local microservices, hardware services, simulator support, data services, algorithms, Python interop, and shared libraries.

## Durable Operating Notes

- Use Domain Analyst for instrument, service, data-flow, simulator, and hardware assumptions.
- Domain Analyst is important because TripleQuadUI is a rewrite of DHS-GUI with enhanced architectural features; compare old-app behavior when requirements are unclear.
- Use feature branches from `master`; the project owner reviews and manually merges accepted branches to `master`.
- Route Product Owner `ready` backlog items to Coordinator Architect, Domain Analyst, and User Experience before implementation. Those roles decide whether to split/update stories or mark them development-ready. Feature Engineering starts only after that triad review and Coordinator branch/worktree/validation handoff.
- Notify the active Discord channel when a feature branch is ready for project-owner code review and manual merge.
- Agents may run builds and tests freely. The primary solution-level build entry point is `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx`.
- Current runtime target is Windows only. Do not spend planning effort preserving Linux compatibility unless Brian changes this direction.
- For developer UI E2E testing, it should be convenient to launch the UI and all local microservices together through a launch profile.
- For production, microservices are expected to run as Windows Services. The Uno UI is launched by the operator or auto-launched in kiosk mode as the only app on the machine.
- Treat real hardware validation separately from simulator validation.
- Limit hardware/instrument behavior changes. Preserve legacy-compatible behavior unless a story explicitly authorizes a hardware change or a clear bug is found and documented for owner review.
- Embedded Python is important for algorithm use, especially machine-learning pieces. Treat Python interop/packaging as product-critical, not dead inherited scaffolding.
- Near-term packaging priority is build reliability before installer, update, or field-service workflow polish.
- Data workflow priority is archived-scan recall first, then clearing history and exporting history. Report generation is lowest priority because need is still uncertain.
- Coordinate changes to shared props, package versions, appsettings, proto contracts, generated code, hardware interfaces, algorithms, and shared data models.
- Register all six roles: Product Owner, Domain Analyst, User Experience, Coordinator Architect, Feature Engineer, and Reviewer Integration.
- Keep Agent OS and OpenClaw references out of the Bruker Detection Git repo.
- Treat TripleQuadUI as a local desktop/microservice application.
- For RC build-quality work, review-ready means committed changes in the parent repo and nested worktrees, plus updated submodule pointers where nested repos changed. A green build against dirty worktrees is validation evidence, but not merge-ready.
- Deferred high-severity package vulnerabilities require explicit Product Owner allowlist approval. Reviewer Integration can accept the technical rationale only after confirming there is no safer scoped package override and the RC validation covers affected data/service paths.

## To Learn Next

- Required SDK, Visual Studio workload, and internal dependency setup.
- Which tests are reliable locally.
- Which product areas matter most for the first agent-driven work.
