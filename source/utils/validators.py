"""
validators.py
-------------
Reusable path, argument, and tool validators shared across the pipeline.
"""

import shutil
import sys
from pathlib import Path

from source.utils.logger import get_logger

log = get_logger(__name__)


class ValidationError(Exception):
    """Raised when a pipeline pre-condition is not met."""


def require_file(path: str | Path, label: str = "File") -> Path:
    """
    Assert that *path* exists and is a regular file.

    Parameters
    ----------
    path : str | Path
    label : str
        Human-readable name for error messages.

    Returns
    -------
    Path

    Raises
    ------
    ValidationError
    """
    p = Path(path)
    if not p.is_file():
        msg = f"{label} not found: {p}"
        log.error(msg)
        raise ValidationError(msg)
    log.debug(f"{label} OK: {p}")
    return p


def require_directory(path: str | Path, label: str = "Directory") -> Path:
    """Assert that *path* exists and is a directory."""
    p = Path(path)
    if not p.is_dir():
        msg = f"{label} not found: {p}"
        log.error(msg)
        raise ValidationError(msg)
    log.debug(f"{label} OK: {p}")
    return p


def require_tool(tool: str) -> str:
    """
    Assert that *tool* is available on PATH (analogous to ``command -v``).

    Raises
    ------
    ValidationError
    """
    if shutil.which(tool) is None:
        msg = f"Required tool not found in PATH: '{tool}'"
        log.error(msg)
        raise ValidationError(msg)
    log.debug(f"Tool available: {tool}")
    return tool


def require_args(argv: list[str], expected: int, usage: str) -> None:
    """
    Validate that the script received the expected number of CLI arguments.

    Parameters
    ----------
    argv : list[str]
        ``sys.argv``
    expected : int
        Number of positional arguments expected **after** the script name.
    usage : str
        Usage string printed on failure.

    Raises
    ------
    SystemExit
    """
    if len(argv) - 1 != expected:
        msg = f"Expected {expected} argument(s), got {len(argv) - 1}.\nUsage: {usage}"
        log.error(msg)
        print(msg, file=sys.stderr)
        sys.exit(1)


def ensure_directory(path: str | Path) -> Path:
    """Create *path* (and parents) if it does not exist. Return Path."""
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    log.debug(f"Directory ensured: {p}")
    return p
