"""Example domain logic. Replace with real business rules."""

from collections.abc import Iterable


def normalize(values: Iterable[float]) -> list[float]:
    """Scale values to the 0-1 range.

    Args:
        values: Numbers to scale.

    Returns:
        The scaled values, in the same order. All zeros if every value is equal.

    Raises:
        ValueError: If no values are given.
    """
    items = list(values)
    if not items:
        raise ValueError("normalize() needs at least one value")
    low, high = min(items), max(items)
    span = high - low
    # Equal values have no spread to scale against; zeros keep the output well-defined.
    if span == 0:
        return [0.0 for _ in items]
    return [(v - low) / span for v in items]
