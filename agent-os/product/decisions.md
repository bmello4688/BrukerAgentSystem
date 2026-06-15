# TripleQuadUI Decisions

## 2026-06-03: Keep Agent OS Outside The Bruker Repo

Decision: store Agent OS project context in `C:\Git\Commercial\MrmETDSpec`, outside the Bruker Detection Git checkout at `C:\Git\Commercial\MrmETDSpec\source\TripleQuadUI`.

Reason: the project owner wants the application repo to stay clean and does not want the agentic system checked into Bruker Detection's `TripleQuadUI.git` repository.

## 2026-06-03: Use Domain Analyst For Local Application Domain Work

Decision: use a Domain Analyst role for application behavior, instrument behavior, service contracts, data flow, and legacy DHS-GUI rewrite compatibility.

Reason: TripleQuadUI is a local Uno/.NET desktop application with ASP.NET-style microservices, shared libraries, and simulator/real-hardware boundaries.

## 2026-06-03: Notify In Discord For Review-Ready Work

Decision: route review-ready and merge-decision notifications to the active Discord `#brukerdev` channel.

Reason: the project owner approved this channel for feature-ready review notifications. Phone numbers, emails, and copied external channels should still not be preserved.

## 2026-06-03: Owner-Reviewed Feature Branch Flow

Decision: agents work on feature branches from `master`, run builds and tests freely, and notify the project owner when a branch is ready for code review and manual merge to `master`.

Reason: the project owner wants final merge control. Rejected reviews must be fixed before merge.

## 2026-06-03: Rewrite Against DHS-GUI With Hardware Guardrails

Decision: use `C:\Git\DHS-GUI` as the legacy application reference for TripleQuadUI rewrite behavior, and limit hardware/instrument changes to explicit feature scope or documented bug fixes requiring owner review.

Reason: TripleQuadUI is a rewrite with enhanced architecture, but hardware/instrument behavior is closely matched to the old application.
