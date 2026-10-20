"""Command-line entry point."""

import logging
import sys

from app.domain.stats import normalize

logger = logging.getLogger(__name__)


def main(argv: list[str] | None = None) -> int:
    """Normalize the numbers given on the command line and write them to stdout.

    Args:
        argv: Arguments without the program name; defaults to sys.argv[1:].

    Returns:
        Process exit code.
    """
    logging.basicConfig(level=logging.INFO)
    args = sys.argv[1:] if argv is None else argv
    try:
        result = normalize(float(a) for a in args)
    except ValueError as exc:
        logger.error("Invalid input: %s", exc)
        return 2
    sys.stdout.write(" ".join(f"{v:.3f}" for v in result) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
