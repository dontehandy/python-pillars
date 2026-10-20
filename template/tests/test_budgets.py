"""Pillar 3: memory budget for the reference workload (budget in pyproject.toml [tool.budgets])."""

import tomllib
import tracemalloc
from pathlib import Path

from app.domain.stats import normalize

PYPROJECT = Path(__file__).parents[1] / "pyproject.toml"
BUDGETS = tomllib.loads(PYPROJECT.read_text())["tool"]["budgets"]


def test_peak_memory_within_budget():
    tracemalloc.start()
    normalize(float(i) for i in range(100_000))
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    assert peak / 1_000_000 <= BUDGETS["peak_memory_mb"]
