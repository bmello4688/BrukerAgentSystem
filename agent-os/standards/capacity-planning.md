# Capacity Planning Standard

TripleQuadUI should run enough agents to keep useful work moving without creating review bottlenecks, integration conflicts, or low-quality parallel churn.

## Default Capacity

- 1 Product Owner
- 1 Domain Analyst when domain, hardware, service, or data-flow discovery is active
- 1 User Experience agent when UI/operator workflow work is active
- 1 Coordinator Architect
- 1-2 Feature Engineers to start
- 1 Reviewer Integration

## Increase Capacity When

- ready stories have independent source ownership
- review capacity is available
- hardware/simulator/test prerequisites are clear
- shared contracts are stable
- the previous batch merged with low conflict and passing validation

## Reduce Capacity When

- stories touch the same shared files or contracts
- hardware, simulator, internal services, licenses, or credentials block validation
- package props, generated code, appsettings, proto contracts, or shared data/algorithm models are changing
- review backlog grows
- agents are discovering requirements during implementation instead of working from ready stories

## Coordinator Responsibility

The Coordinator Architect owns the active batch limit and should document:

- active agents and roles
- branches/worktrees
- source ownership
- shared paths
- validation matrix
- known bottlenecks
