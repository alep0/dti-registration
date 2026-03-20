"""
test_bvec_bval_converter.py
----------------------------
Unit tests for source/core/bvec_bval_converter.py.

Run with:
    pytest validations/test_bvec_bval_converter.py -v
"""

import numpy as np
import pytest
import tempfile
from pathlib import Path
import sys

from source.utils.validators import ValidationError
from source.core.bvec_bval_converter import (
    read_bval,
    read_bvec_with_sign_correction,
    convert_bval_bvec_to_txt,
    _SIGN_CORRECTIONS,
    _N_DIRS,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# ── Fixtures ──────────────────────────────────────────────────────────────────


def _write_bval(path: Path, values: list[float]) -> None:
    path.write_text(" ".join(str(v) for v in values) + "\n", encoding="utf-8")


def _write_bvec(path: Path, matrix: np.ndarray) -> None:
    """Write bvec in ExploreDTI format (one column per direction, rows=xyz)."""
    lines = []
    for col in range(matrix.shape[1]):
        lines.append("\t".join(str(matrix[row, col]) for row in range(matrix.shape[0])))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ── Tests: _SIGN_CORRECTIONS shape ───────────────────────────────────────────

def test_sign_corrections_shape():
    assert _SIGN_CORRECTIONS.shape == (_N_DIRS, 3)


def test_sign_corrections_only_plus_minus_one():
    unique = np.unique(np.abs(_SIGN_CORRECTIONS))
    assert len(unique) == 1 and unique[0] == 1.0


# ── Tests: read_bval ──────────────────────────────────────────────────────────

class TestReadBval:
    def test_reads_values_correctly(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "test.bval"
            expected = [0.0, 1000.0, 2000.0, 3000.0]
            _write_bval(p, expected)
            result = read_bval(p)
            assert result == expected

    def test_missing_file_raises(self):
        with pytest.raises(ValidationError):
            read_bval("/nonexistent/path.bval")

    def test_returns_list_of_floats(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "test.bval"
            _write_bval(p, [0, 1000])
            result = read_bval(p)
            assert all(isinstance(v, float) for v in result)


# ── Tests: read_bvec_with_sign_correction ─────────────────────────────────────

class TestReadBvec:
    def _make_bvec_file(self, tmpdir: str) -> tuple[Path, np.ndarray]:
        """Create a synthetic bvec file with all ones for easy testing."""
        p = Path(tmpdir) / "test.bvec"
        raw = np.ones((_N_DIRS, 3), dtype=np.float64)
        _write_bvec(p, raw.T)  # transpose: rows=xyz, cols=dirs
        return p, raw

    def test_output_shape(self):
        with tempfile.TemporaryDirectory() as d:
            p, _ = self._make_bvec_file(d)
            result = read_bvec_with_sign_correction(p)
            assert result.shape == (_N_DIRS, 3)

    def test_sign_applied_to_known_direction(self):
        with tempfile.TemporaryDirectory() as d:
            p, _ = self._make_bvec_file(d)
            result = read_bvec_with_sign_correction(p)
            # Direction 4 x-component should be -1 (correction is -1)
            assert result[4, 0] == -1.0

    def test_missing_file_raises(self):
        with pytest.raises(ValidationError):
            read_bvec_with_sign_correction("/nonexistent.bvec")


# ── Tests: convert_bval_bvec_to_txt ──────────────────────────────────────────

class TestConvertBvalBvecToTxt:
    def test_output_files_created(self):
        with tempfile.TemporaryDirectory() as d:
            bval_in = Path(d) / "in.bval"
            bvec_in = Path(d) / "in.bvec"
            bval_out = Path(d) / "out_bval.txt"
            bvec_out = Path(d) / "out_bvec.txt"

            _write_bval(bval_in, [0.0] * _N_DIRS)
            raw = np.ones((_N_DIRS, 3))
            _write_bvec(bvec_in, raw.T)

            convert_bval_bvec_to_txt(bval_in, bval_out, bvec_in, bvec_out)

            assert bval_out.exists()
            assert bvec_out.exists()

    def test_bval_line_count_matches_directions(self):
        with tempfile.TemporaryDirectory() as d:
            bval_in = Path(d) / "in.bval"
            bvec_in = Path(d) / "in.bvec"
            bval_out = Path(d) / "out_bval.txt"
            bvec_out = Path(d) / "out_bvec.txt"

            values = list(range(_N_DIRS))
            _write_bval(bval_in, values)
            _write_bvec(bvec_in, np.ones((_N_DIRS, 3)).T)

            convert_bval_bvec_to_txt(bval_in, bval_out, bvec_in, bvec_out)

            lines = bval_out.read_text().strip().splitlines()
            assert len(lines) == _N_DIRS

    def test_bvec_line_count_matches_directions(self):
        with tempfile.TemporaryDirectory() as d:
            bval_in = Path(d) / "in.bval"
            bvec_in = Path(d) / "in.bvec"
            bval_out = Path(d) / "out_bval.txt"
            bvec_out = Path(d) / "out_bvec.txt"

            _write_bval(bval_in, [0.0] * _N_DIRS)
            _write_bvec(bvec_in, np.ones((_N_DIRS, 3)).T)

            convert_bval_bvec_to_txt(bval_in, bval_out, bvec_in, bvec_out)

            lines = bvec_out.read_text().strip().splitlines()
            assert len(lines) == _N_DIRS

    def test_missing_input_raises(self):
        with pytest.raises(ValidationError):
            convert_bval_bvec_to_txt(
                "/nonexistent.bval", "/tmp/out.txt",
                "/nonexistent.bvec", "/tmp/out2.txt",
            )
