# TripleQuadUI Release Candidate Scope

This is the Product Owner RC scope reference captured from Brian's interview answers on 2026-06-10. Keep this file outside the Bruker Detection `TripleQuadUI.git` repo.

## Stakeholder Goal

Deliver a simulator-signoff release candidate that demonstrates the core operator journey end-to-end with reliable build quality, algorithm proof, history operations, and alarm/collection resilience. RC is not the production installer or final hardware validation milestone.

## RC Product Outcome

An operator can launch the RC in a developer/demo environment, log in, wake the system, reach readiness, collect confidence-check and normal samples, see detection/alarm behavior, persist and recall collected scans, clear/export history, and complete a live simulator demo with accepted build/test evidence.

## Included Workflows

RC must demonstrably complete these workflows end-to-end:

- Login and access gating.
- Instrument wake, readiness, and status.
- Live sample collection and confidence check.
- Normal non-confidence sample collection.
- Fault, not-ready, and recovery paths.
- Alarm display, silence, clear, and return to Ready.
- Alarm persistence across navigation/page changes.
- Alarm survival across service/UI restart or reconnect.
- Repeated or multiple-substance detections consolidated into one alarm for RC.
- Archived scan recall for scans created in the current TripleQuadUI simulator flow.
- Clear all history, clear selected scan/sample, and clear all history before a selected date.
- Export history to a local folder.

## Excluded From RC

These are explicitly out of RC scope unless Brian reprioritizes them:

- Reports and report generation.
- Options/substance library management.
- Maintenance workflows.
- User management.
- Print options.
- Detailed device/desorber screens.
- Migrated/imported legacy DHS-GUI archive recall.
- Recall from the real deployed DHS-GUI archive location.
- Production Windows Service installer or installable service deployment.
- Real hardware/manual signoff as an RC blocker.

## Runtime And Launch Decisions

- Runtime target is Windows only.
- RC should support a single developer launch profile that starts the Uno UI, required microservices, and simulator dependencies.
- Production posture may be documented for RC; Windows Services do not need to be implemented or installable for RC.
- Uno UI production launch remains operator-launched or kiosk auto-launched as a post-RC deployment concern.

## Data And History Decisions

- Archived recall only needs scans created by the current TripleQuadUI simulator flow for RC.
- Clear history must support:
  - clear all history,
  - clear selected scan/sample,
  - clear all history before a selected date.
- Export history to a local folder is enough for RC.
- Clear/export can be available to any logged-in operator for RC.
- Later user management should make clear/export a supervisor task.

## Algorithm And Python Proof

RC needs confidence that algorithms work and are testable. Desired proof includes:

- Existing unit/integration tests proving algorithm invocation.
- Simulator-driven sample producing expected detection output in the UI.
- Known fixture/data file producing known substance results.
- SME/manual review of algorithm parity with the other application.

Embedded Python and ML infrastructure should be treated as product-critical. If a proof item cannot be completed before RC, it needs explicit Product Owner and Reviewer Integration review.

## Build And Quality Gate

RC is not allowed to simply accept all existing warnings and package vulnerability warnings. The gate is:

- Relevant focused builds pass.
- Full solution build passes.
- Relevant focused tests pass or have reviewed, documented blockers.
- Warning cleanup is performed where reasonable.
- Package vulnerability cleanup is performed where reasonable.
- Remaining warnings/vulnerabilities require a reviewed allowlist with rationale.
- Simulator validation is clearly labeled separately from later real hardware/manual validation.

## Validation And Signoff

Simulator-only validation is enough for RC signoff. Hardware/manual validation is required later but is not an RC blocker.

The RC signoff artifact is a live simulator demo. Supporting validation notes, screenshots, and logs are useful but are secondary to the live demo.

Minimum demo path:

1. Launch RC through the single developer profile.
2. Log in.
3. Wake system and reach readiness.
4. Complete confidence-check collection with persisted sample.
5. Complete normal non-confidence collection.
6. Trigger alarm, silence audio, navigate away/back, clear alert, and return to Ready.
7. Demonstrate alarm survival across restart/reconnect where practical.
8. Recall a simulator-created archived scan.
9. Clear selected history, clear history before date, and clear all history.
10. Export history to a local folder.
11. Show algorithm proof through tests, known fixture, simulator detection output, or SME-reviewed parity evidence.

## Hardware And SME Notes

- Real hardware/manual validation is deferred until after RC.
- Changes to hardware semantics, readiness thresholds, swab state, desorber behavior, MS workstation behavior, proto contracts, data persistence formats, or algorithm detection behavior still require owner/SME review.
- The RC should preserve DHS-GUI-compatible semantics for included workflows unless a bug fix is documented for review.

## Backlog Mapping

- BL-008 becomes part of the RC build quality gate.
- BL-009 becomes the RC launch profile and production runtime documentation story.
- BL-010 becomes the RC algorithm/Python proof story.
- BL-011 becomes current-flow archived scan recall.
- BL-012 expands for clear selected, clear all, clear before date, and local-folder export.
- BL-006 and BL-007 remain done foundations but their workflows must be regression-validated in the RC demo.
