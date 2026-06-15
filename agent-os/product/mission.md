# TripleQuadUI Mission

## Purpose

TripleQuadUI is the Bruker Detection local desktop application workspace for MrmETD mass spectrometry analyzer UI, microservices, hardware communication, simulation, data services, and analysis libraries.

## Users

- Operators and testers who need clear analyzer workflows and reliable instrument feedback.
- Engineers and support staff working with instrument communication, microservices, simulators, data services, and analysis algorithms.
- Engineering support for rewriting the legacy DHS-GUI application with improved architecture while respecting hardware, service, and company constraints.

## Product Principles

- Preserve instrument correctness and operator trust.
- Preserve important legacy DHS-GUI behavior unless a feature intentionally changes it.
- Prefer explicit service and hardware contracts over hidden coupling.
- Keep simulator behavior useful without confusing it for real hardware validation.
- Treat shared libraries, proto contracts, appsettings, and package props as high-coordination areas.
- Protect Bruker Detection IP, internal infrastructure details, and sensitive operational data.
- Keep local development tooling and orchestration details out of the Bruker Detection Git repo.
- Treat TripleQuadUI as a local desktop/microservice application.

## Current Workspace Scope

- Analyzer UI and host: `MrmEtdMassSpecAnalyzer/`
- Hardware and simulator services: `HardwareLayer/`
- Substance analyzer core services/models: `CoreLogicLayer/`
- Shared data, algorithms, logging, and Python interop libraries: `CommonLibraries/`
- Shared Uno/platform libraries: `CommonLibraries.Uno/`
