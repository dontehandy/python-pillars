import pytest

from app.domain.stats import normalize


def test_scales_to_unit_range():
    assert normalize([2, 4, 6]) == [0.0, 0.5, 1.0]


def test_equal_values_become_zero():
    assert normalize([3, 3]) == [0.0, 0.0]


def test_empty_input_rejected():
    with pytest.raises(ValueError):
        normalize([])
