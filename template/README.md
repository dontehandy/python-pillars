# app

## Quality gates
`scripts/check.sh` runs every pillar gate (security, correctness, performance, maintainability, architecture,
reliability) from the Python principles and prints a scorecard. All gates must PASS, or be WAIVED by a
trade-off in `tradeoffs.toml` backed by a decision record in `docs/decisions/`.

## Setup
    python3 -m venv .venv
    .venv/bin/pip install -e '.[dev]'
    .venv/bin/pip freeze --exclude-editable > requirements.lock
    scripts/check.sh
