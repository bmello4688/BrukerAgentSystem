# Definition Of Done

A TripleQuadUI story is done when the change is documented, tested or otherwise validated, reviewed, and ready for project-owner code review and manual merge.

## Required

- Acceptance criteria are satisfied or explicitly deferred.
- Changed behavior is summarized.
- Affected files and projects are listed.
- Focused validation commands and outcomes are recorded.
- Skipped validation is explained, especially for hardware, simulator, internal services, licenses, or credentials.
- Contract impacts are documented for APIs, gRPC/proto, settings, models, generated code, hardware interfaces, or data files.
- Safety/security/privacy risks are disclosed.
- Reviewer Integration gives go/no-go for owner review.
- The configured Discord channel has been notified when the feature branch is ready for manual review/merge.
- Hardware/instrument behavior changes are explicitly authorized or documented as bug fixes for owner review.
- No agent usage, OpenClaw, orchestration, or Agent OS references were introduced into the Bruker Detection repo.

## Not Done When

- Code exists but no validation evidence is provided.
- Shared contract consumers were not considered.
- Hardware-dependent behavior was validated only with a simulator without calling out the gap.
- Unrelated changes are mixed into the story.
- Follow-up work is hidden in chat rather than recorded in the handoff or spec.
