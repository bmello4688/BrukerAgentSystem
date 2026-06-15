# Conference-Check Swab Workflow Standards

- Follow `agent-os/standards/source-control.md`.
- Follow `agent-os/standards/testing.md`.
- Follow `agent-os/standards/backend/api.md` for service, proto, settings, and model changes.
- Follow `agent-os/standards/definition-of-ready.md` before implementation starts.
- Follow `agent-os/standards/definition-of-done.md` before review-ready handoff.

## Extra Guardrails

- Preserve DHS-GUI-compatible hardware/instrument behavior unless Brian explicitly approves a change.
- Treat simulator validation and real-hardware validation separately.
- Treat proto contracts, appsettings, generated code, hardware interfaces, shared models, and scan series persistence as high-coordination areas.
- Keep local planning/tooling references out of the Bruker Detection Git repo.
