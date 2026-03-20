"""
bvec_bval_converter.py
-----------------------
Converts ExploreDTI-format bval/bvec files to plain-text format compatible
with Dipy, applying the sign corrections required for Matlab→Dipy coordinate
conventions.

Replaces: bvalbvec_engine_v5.py
"""

import sys
import numpy as np
from pathlib import Path
from typing import Sequence

from source.utils.logger import get_logger
from source.utils.validators import require_file, ensure_directory, require_args

log = get_logger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# Sign correction table (ExploreDTI → Dipy)
# Rows = gradient directions (0-indexed, 0..32); Cols = x, y, z
# ──────────────────────────────────────────────────────────────────────────────

_N_DIRS = 33

# Build the sign-correction matrix (default +1, selectively overridden)
_SIGN_CORRECTIONS: np.ndarray = np.ones((_N_DIRS, 3), dtype=np.float32)

# x-axis corrections
for _idx in [4, 15, 16, 19, 20]:
    _SIGN_CORRECTIONS[_idx, 0] = -1.0

# y-axis corrections
for _idx in [5, 6, 9, 10, 13, 14, 17, 18, 21, 22, 25, 26, 27, 28, 29, 30, 31, 32]:
    _SIGN_CORRECTIONS[_idx, 1] = -1.0

# z-axis corrections
for _idx in [11, 12, 13, 14, 17, 18, 21, 22, 27, 28, 29, 30, 31, 32]:
    _SIGN_CORRECTIONS[_idx, 2] = -1.0
for _idx in [19, 20]:
    _SIGN_CORRECTIONS[_idx, 2] = 1.0   # explicit +1 (no-op, kept for clarity)


# ──────────────────────────────────────────────────────────────────────────────
# Readers
# ──────────────────────────────────────────────────────────────────────────────

def read_bval(bval_path: str | Path) -> list[float]:
    """
    Parse an ExploreDTI ``.bval`` file into a Python list of floats.

    Parameters
    ----------
    bval_path : str | Path

    Returns
    -------
    list[float]
    """
    path = require_file(bval_path, "bval file")
    log.info(f"Reading bval: {path}")
    content = path.read_text(encoding="utf-8")
    tokens = content.split()
    values = [float(t) for t in tokens if t]
    log.info(f"Read {len(values)} b-values.")
    return values


def read_bvec_with_sign_correction(bvec_path: str | Path) -> np.ndarray:
    """
    Parse an ExploreDTI ``.bvec`` file and apply sign corrections.

    The file format has one gradient direction per column (rows are x/y/z).
    Values are separated by whitespace; rows are separated by newlines.

    Parameters
    ----------
    bvec_path : str | Path

    Returns
    -------
    np.ndarray
        Shape ``(_N_DIRS, 3)`` with sign corrections applied.
    """
    path = require_file(bvec_path, "bvec file")
    log.info(f"Reading bvec: {path}")

    raw = np.zeros((_N_DIRS + 1, 3), dtype=np.float64)  # +1 header row safety
    content = path.read_text(encoding="utf-8")

    row = 0
    for line in content.splitlines():
        tokens = line.split()
        for col, token in enumerate(tokens):
            if row < raw.shape[0] and col < 3:
                raw[row, col] = float(token)
        row += 1

    gradients = raw[:_N_DIRS, :]  # trim to expected directions
    corrected = gradients * _SIGN_CORRECTIONS
    log.info(f"bvec sign correction applied to {_N_DIRS} directions.")
    return corrected


# ──────────────────────────────────────────────────────────────────────────────
# Writers
# ──────────────────────────────────────────────────────────────────────────────

def _write_scalar_list(values: Sequence[float], out_path: Path) -> None:
    ensure_directory(out_path.parent)
    with open(out_path, "w", encoding="utf-8") as fh:
        for v in values:
            fh.write(f"{v}\n")
    log.info(f"Saved: {out_path}")


def _write_matrix(matrix: np.ndarray, out_path: Path) -> None:
    ensure_directory(out_path.parent)
    with open(out_path, "w", encoding="utf-8") as fh:
        for row in matrix:
            fh.write(" ".join(str(v) for v in row) + "\n")
    log.info(f"Saved: {out_path}")


# ──────────────────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────────────────

def convert_bval_bvec_to_txt(
    bval_in: str | Path,
    bval_out: str | Path,
    bvec_in: str | Path,
    bvec_out: str | Path,
) -> None:
    """
    Convert a bval/bvec pair from ExploreDTI format to plain text (Dipy-ready).

    Parameters
    ----------
    bval_in : str | Path
        Input ``.bval`` file.
    bval_out : str | Path
        Output ``.txt`` file for b-values.
    bvec_in : str | Path
        Input ``.bvec`` file.
    bvec_out : str | Path
        Output ``.txt`` file for gradient directions (sign-corrected).
    """
    bvals = read_bval(bval_in)
    bvecs = read_bvec_with_sign_correction(bvec_in)

    _write_scalar_list(bvals, Path(bval_out))
    _write_matrix(bvecs, Path(bvec_out))

    log.info("bval/bvec conversion complete.")


# ──────────────────────────────────────────────────────────────────────────────
# CLI entry point
# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    require_args(
        sys.argv,
        expected=4,
        usage=(
            "python3 bvec_bval_converter.py "
            "<bval_in> <bval_out> <bvec_in> <bvec_out>"
        ),
    )
    try:
        convert_bval_bvec_to_txt(
            bval_in=sys.argv[1],
            bval_out=sys.argv[2],
            bvec_in=sys.argv[3],
            bvec_out=sys.argv[4],
        )
    except Exception as exc:
        log.error(f"Conversion failed: {exc}")
        sys.exit(1)
