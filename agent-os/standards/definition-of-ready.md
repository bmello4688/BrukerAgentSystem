# Definition Of Ready

A TripleQuadUI story is ready when an agent can start without guessing about value, dependencies, domain behavior, contracts, safety/security, or validation.

## Required

- Stakeholder goal and user/product outcome are clear.
- Acceptance criteria are testable.
- Affected projects and shared files are identified.
- Required domain behavior is documented, or a Domain Analyst/SME discovery task is scheduled first.
- Contract impacts are identified for services, gRPC/proto, settings, data models, hardware interfaces, algorithms, or generated code.
- Validation expectations are defined, including whether simulator or real hardware is required.
- Non-goals and known risks are stated.

## Not Ready When

- Hardware, simulator, internal-service, license, or credential needs are unknown.
- The affected project or service boundary is unclear.
- Shared contracts may change but no Coordinator plan exists.
- Expected behavior depends on Bruker SME knowledge that has not been captured.
- No meaningful validation path is identified.
