# Service/API Standard

## Scope

Applies to service, gRPC/proto, appsettings, data-service, microservice-host, and service-client changes in TripleQuadUI.

## Contracts

- Treat proto files, service client APIs, shared models, and appsettings keys as contracts.
- Preserve compatibility unless the story explicitly requires a breaking change.
- Document producer and consumer impacts for every contract change.
- Coordinate generated-code updates with the Coordinator Architect.

## Configuration

- Keep environment-specific settings in the existing `appsettings*.json` and launch-settings patterns.
- Do not commit secrets, credentials, machine-specific paths, or internal-only values unless they already belong in versioned config.
- When adding settings, document defaults, required environments, and simulator versus real-hardware differences.

## Services

- Prefer existing dependency injection, logging, options, and error-handling patterns.
- Make failure modes explicit, especially for hardware communication, service startup, retries, timeouts, and unavailable dependencies.
- Avoid hiding hardware or internal-service assumptions in UI code.

## Validation

For service/API changes, include the most relevant available checks:

- focused project build
- service test project
- consumer project build
- simulator smoke check
- real hardware/manual validation status when required
