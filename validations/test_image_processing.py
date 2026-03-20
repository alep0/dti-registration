"""
test_image_processing.py
-------------------------
Unit and integration tests for source/core/image_processing.py.

Run with:
    pytest validations/test_image_processing.py -v
"""

import numpy as np
import pytest
import tempfile
from pathlib import Path

# ── Import under test ─────────────────────────────────────────────────────────

import sys

from source.utils.validators import ValidationError
from source.core.image_processing import (
    _apply_mask,
    _transform_silvia,
    _transform_standard,
    OP_SILVIA,
)

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# ── Helpers ───────────────────────────────────────────────────────────────────

def _make_brain_4d(shape=(10, 10, 10, 5)):
    return np.random.rand(*shape).astype(np.float32)

def _make_mask_3d(shape=(10, 10, 10), fill=1):
    mask = np.ones(shape, dtype=np.float32) * fill
    # Simulate skull: zero the outermost voxel shell
    mask[0, :, :] = 0
    mask[-1, :, :] = 0
    return mask

# ── Tests: _apply_mask ────────────────────────────────────────────────────────

class TestApplyMask:
    def test_zeros_outside_mask(self):
        mask = np.array([[[1, 0], [0, 1]], [[1, 1], [0, 0]]], dtype=np.float32)
        brain = np.ones_like(mask)
        result = _apply_mask(mask, brain)
        assert result[0, 1, 0] == 0.0
        assert result[0, 0, 0] == 1.0

    def test_shape_preserved(self):
        shape = (8, 9, 7)
        mask = np.ones(shape, dtype=np.float32)
        brain = np.random.rand(*shape).astype(np.float32)
        result = _apply_mask(mask, brain)
        assert result.shape == shape

    def test_mismatched_shapes_raise(self):
        mask = np.ones((4, 4, 4), dtype=np.float32)
        brain = np.ones((4, 4, 5), dtype=np.float32)
        with pytest.raises(ValidationError):
            _apply_mask(mask, brain)

    def test_full_zero_mask_gives_zero_brain(self):
        mask = np.zeros((5, 5, 5), dtype=np.float32)
        brain = np.ones((5, 5, 5), dtype=np.float32)
        result = _apply_mask(mask, brain)
        assert np.all(result == 0)

    def test_full_one_mask_preserves_brain(self):
        mask = np.ones((5, 5, 5), dtype=np.float32)
        brain = np.random.rand(5, 5, 5).astype(np.float32)
        result = _apply_mask(mask, brain)
        np.testing.assert_array_almost_equal(result, brain)


# ── Tests: _transform_silvia ──────────────────────────────────────────────────

class TestTransformSilvia:
    def test_drops_time_dimension(self):
        brain_4d = _make_brain_4d((6, 7, 8, 3))
        mask_3d = _make_mask_3d((6, 7, 8))
        brain_t, mask_t = _transform_silvia(brain_4d, mask_3d)
        assert brain_t.shape == (6, 7, 8)
        assert mask_t.shape == (6, 7, 8)

    def test_extracts_first_volume(self):
        brain_4d = _make_brain_4d((4, 4, 4, 2))
        brain_4d[:, :, :, 0] = 1.0
        brain_4d[:, :, :, 1] = 99.0
        mask_3d = np.ones((4, 4, 4), dtype=np.float32)
        brain_t, _ = _transform_silvia(brain_4d, mask_3d)
        assert np.all(brain_t == 1.0)


# ── Tests: _transform_standard ───────────────────────────────────────────────

class TestTransformStandard:
    def test_output_shape_reflects_axis_swap(self):
        # (A, B, C) → after reflection+transpose(0,2,1) → (A, C, B)
        brain = np.random.rand(4, 5, 6).astype(np.float32)
        mask = np.ones((4, 5, 6), dtype=np.float32)
        brain_t, mask_t = _transform_standard(brain, mask)
        assert brain_t.shape == (4, 6, 5)
        assert mask_t.shape == (4, 6, 5)

    def test_x_axis_reflected(self):
        brain = np.arange(24, dtype=np.float32).reshape(4, 3, 2)
        mask = np.ones((4, 3, 2), dtype=np.float32)
        brain_t, _ = _transform_standard(brain, mask)
        # After reflection: brain_t[0] should come from brain[-1]
        np.testing.assert_array_equal(
            brain_t[0, :, :], np.transpose(brain[-1, :, :], (1, 0))
        )


# ── Tests: CLI argument handling ──────────────────────────────────────────────

class TestCLIArguments:
    def test_missing_args_exits(self):
        from source.utils.validators import require_args
        with pytest.raises(SystemExit):
            require_args(
                ["script.py"],  # no positional args
                expected=3,
                usage="script.py <a> <b> <c>",
            )

    def test_correct_arg_count_passes(self):
        from source.utils.validators import require_args
        # Should not raise
        require_args(["script.py", "a", "b", "c"], expected=3, usage="")


# ── Tests: slice_rotate_and_mask (integration with mocked I/O) ───────────────

class TestSliceRotateAndMask:
    def test_invalid_operation_raises(self):
        from source.core.image_processing import slice_rotate_and_mask
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create dummy input files
            import nibabel as nib
            brain_path = Path(tmpdir) / "brain.nii"
            mask_path = Path(tmpdir) / "mask.nii"
            brain_out = Path(tmpdir) / "brain_out.nii.gz"
            mask_out = Path(tmpdir) / "mask_out.nii.gz"

            brain_data = np.random.rand(4, 4, 4, 2).astype(np.float32)
            mask_data = np.ones((4, 4, 4), dtype=np.float32)
            affine = np.eye(4)

            nib.save(nib.Nifti1Image(brain_data, affine), str(brain_path))
            nib.save(nib.Nifti1Image(mask_data, affine), str(mask_path))

            with pytest.raises(ValueError, match="Unsupported operation"):
                slice_rotate_and_mask(99, brain_path, mask_path, brain_out, mask_out)

    def test_missing_brain_raises(self):
        from source.core.image_processing import slice_rotate_and_mask
        with pytest.raises(ValidationError):
            slice_rotate_and_mask(
                OP_SILVIA,
                "/nonexistent/brain.nii",
                "/nonexistent/mask.nii",
                "/tmp/brain_out.nii.gz",
                "/tmp/mask_out.nii.gz",
            )
