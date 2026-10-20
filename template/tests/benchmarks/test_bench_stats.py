"""Pillar 3: benchmarks for critical paths, compared against the saved baseline."""

from app.domain.stats import normalize

DATA = [float(i) for i in range(10_000)]


def test_bench_normalize(benchmark):
    benchmark(normalize, DATA)
