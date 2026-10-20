# NNNN — <decision title>

- **Date:** YYYY-MM-DD
- **Status:** proposed | accepted | superseded by NNNN
- **Review by:** YYYY-MM-DD (security trade-offs: within 30 days)

## Context
What problem are we solving, and what constraints apply (budgets, deadlines, existing code)?

## Options × pillars matrix
Score each option per pillar: **✓ meets** · **~ trade-off (explain below)** · **✗ fails**.
An option with ✗ on Security is not eligible.

| Pillar | Option A: … | Option B: … | Option C: … |
|---|---|---|---|
| 1. Security | | | |
| 2. Correctness | | | |
| 3. Performance (vs budget) | | | |
| 4. Maintainability | | | |
| 5. Architecture | | | |
| 6. Reliability | | | |

Evidence: measurements (benchmarks, memory, startup), sources from PRINCIPLES.md, links.

## Decision
Chosen option and the one-sentence reason.

## Trade-offs accepted
For each `~`: what we give up, why it's acceptable, and what would make us revisit it.
If a gate will fail because of this, add a matching `[[waiver]]` in `tradeoffs.toml` pointing here.

## Consequences
What changes in the code, budgets, or principles as a result.
