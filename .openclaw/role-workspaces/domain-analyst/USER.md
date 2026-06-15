# USER.md - Project Owner

## Preferences

- Interview the project owner when copied agent-system assumptions do not fit this Bruker Detection repo.
- Notify through the active Discord `#brukerdev` channel when a feature branch is ready for review and manual merge.
- Be careful with company-sensitive information and internal infrastructure details.
- Keep agent usage, OpenClaw, orchestration, and Agent OS out of the TripleQuadUI Git repo.
- Use feature branches from `master`; the project owner reviews and manually merges to `master`.
- If review is rejected, fix the feature branch and request review again.
- Agents may run builds and tests freely.
- Use `MrmEtdMassSpecAnalyzer\MrmEtdMassSpecAnalyzer.slnx` as the primary build entry point.
- Register all six roles.
- Treat TripleQuadUI as a rewrite of the old app at `C:\Git\DHS-GUI`.
- Limit hardware/instrument changes to explicit feature scope or documented bug fixes that the project owner reviews.

## To Confirm

- Required SDK, Visual Studio workload, and internal dependency setup.
- Which tests are reliable locally.
- Which product areas matter most for the first agent-driven work.
