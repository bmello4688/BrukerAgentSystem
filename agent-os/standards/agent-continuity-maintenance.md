# Agent Continuity Maintenance

Preserve useful TripleQuadUI context for future agents while keeping raw local state, personal details, runtime IDs, contact details, credentials, customer data, and sensitive company data out of durable project documentation.

## Save

- durable project architecture notes
- stable build/test commands
- confirmed hardware/simulator validation requirements
- service, data-flow, and contract insights
- recurring risks and reviewer expectations
- decisions that future agents should know before changing code

## Do Not Save

- raw chat transcripts
- credentials, tokens, contact details, runtime IDs, or machine-specific secrets
- customer, lab, or production data
- unapproved internal infrastructure details
- agent personality boilerplate unless it changes project operating behavior

## Destination

Use `agent-os/product/agent-continuity.md` for curated portable context.

Use feature specs or handoff files for story-specific details.

Reviewer Integration should confirm updates are useful to future TripleQuadUI agents, not just a transcript of what happened.
