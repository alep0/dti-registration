"""
image_processing.py
--------------------
Core NIfTI image processing for the DTI registration pipeline.

Handles:
- 4-D → 3-D slicing (removal of the time dimension)
- Axis transposition / reflection for Silvia vs. WHS-standard rat spaces
- Brain extraction via binary mask (skull stripping)

Replaces: standard_rats_engine.py (v8)
"""

import sys
import numpy as np
from pathlib import Path

from dipy.io.image import load_nifti, save_nifti

from source.utils.logger import get_logger
from source.utils.validators import (
    ValidationError,
    require_file,
    ensure_directory,
    require_args,
)
from source.utils.config_loader import load_config

log = get_logger(__name__)

# ──────────────────────────────────────────────
# Public constants
# ──────────────────────────────────────────────
OP_SILVIA = 1    # Silvia (experimental) rat
OP_STANDARD = 2  # WHS standard rat


# ──────────────────────────────────────────────
# Internal helpers
# ──────────────────────────────────────────────

def _apply_mask(mask_volume: np.ndarray, brain_volume: np.ndarray) -> np.ndarray:
    """
    Zero-out voxels in *brain_volume* where *mask_volume* is non-positive.

    Vectorised implementation – avoids Python-level nested loops.

    Parameters
    ----------
    mask_volume : np.ndarray
        Binary (or near-binary) mask array.
    brain_volume : np.ndarray
        Brain image with identical shape.

    Returns
    -------
    np.ndarray
        Masked brain image (float32).
    """
    if mask_volume.shape != brain_volume.shape:
        raise ValidationError(
            f"Mask shape {mask_volume.shape} does not match "
            f"brain shape {brain_volume.shape}."
        )
    binary_mask = (mask_volume > 0).astype(np.float32)
    return brain_volume * binary_mask


def _transform_silvia(brain: np.ndarray, mask: np.ndarray):
    """
    Transform Silvia-rat volumes.

    Steps
    -----
    1. Remove time dimension (axis 3 → squeeze to 3-D).
    2. Identity transposition retained (no reorientation needed for Silvia).

    Returns
    -------
    tuple[np.ndarray, np.ndarray]
        (transformed_brain, transformed_mask)
    """
    log.info("Applying Silvia-rat transformations.")
    brain_3d = brain[:, :, :, 0]          # drop time axis
    brain_t = np.transpose(brain_3d, (0, 1, 2))
    mask_t = np.transpose(mask[:, :, :], (0, 1, 2))
    return brain_t, mask_t


def _transform_standard(brain: np.ndarray, mask: np.ndarray):
    """
    Transform WHS standard-rat volumes.

    Steps
    -----
    1. Reflect x-axis (left–right flip).
    2. Reorder axes: (sagittal, axial, coronal) → (sagittal, coronal, axial).

    Returns
    -------
    tuple[np.ndarray, np.ndarray]
        (transformed_brain, transformed_mask)
    """
    log.info("Applying WHS-standard-rat transformations.")
    brain_t = np.transpose(brain[::-1, :, :], (0, 2, 1))
    mask_t = np.transpose(mask[::-1, :, :], (0, 2, 1))
    return brain_t, mask_t


# ──────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────

def slice_rotate_and_mask(
    operation: int,
    brain_path_in: str | Path,
    mask_path_in: str | Path,
    brain_path_out: str | Path,
    mask_path_out: str | Path,
) -> None:
    """
    Slice, reorient, and skull-strip a NIfTI brain image.

    Parameters
    ----------
    operation : int
        ``1`` for Silvia (experimental) rat; ``2`` for WHS standard rat.
    brain_path_in : str | Path
        Input brain NIfTI file.
    mask_path_in : str | Path
        Input binary mask NIfTI file.
    brain_path_out : str | Path
        Output path for the skull-stripped, reoriented brain.
    mask_path_out : str | Path
        Output path for the reoriented mask.

    Raises
    ------
    ValidationError
        On missing input files or shape mismatches.
    ValueError
        On unsupported *operation* value.
    """
    brain_in = require_file(brain_path_in, "Brain NIfTI")
    mask_in = require_file(mask_path_in, "Mask NIfTI")

    log.info(f"Loading brain:  {brain_in}")
    log.info(f"Loading mask:   {mask_in}")

    brain_data, brain_affine = load_nifti(str(brain_in))
    mask_data, mask_affine = load_nifti(str(mask_in))

    log.info(f"Brain shape: {brain_data.shape} | Mask shape: {mask_data.shape}")

    if operation == OP_SILVIA:
        brain_t, mask_t = _transform_silvia(brain_data, mask_data)
    elif operation == OP_STANDARD:
        brain_t, mask_t = _transform_standard(brain_data, mask_data)
    else:
        raise ValueError(f"Unsupported operation: {operation!r}. Use 1 (Silvia) or 2 (Standard).")

    masked_brain = _apply_mask(mask_t, brain_t)
    log.info("Skull stripping applied.")

    ensure_directory(Path(brain_path_out).parent)
    ensure_directory(Path(mask_path_out).parent)

    save_nifti(str(brain_path_out), masked_brain, brain_affine)
    save_nifti(str(mask_path_out), mask_t, mask_affine)

    log.info(f"Saved brain → {brain_path_out}")
    log.info(f"Saved mask  → {mask_path_out}")


# ──────────────────────────────────────────────
# CLI entry point
# ──────────────────────────────────────────────

def _build_paths(root: Path, rat: str, group: str) -> tuple:
    data_dir = root / "data" / "nifti" / group
    out_dir = root / "results" / "pre" / "sliced_3d_masked" / group
    brain_in = data_dir / f"{rat}_HARDI.nii"
    mask_in = data_dir / f"{rat}_HARDI_mask.nii"
    brain_out = out_dir / rat / f"{rat}_syn_b02m_za_.nii.gz"
    mask_out = out_dir / rat / f"{rat}_syn_b02_m_za_.nii.gz"
    return brain_in, mask_in, brain_out, mask_out


if __name__ == "__main__":
    require_args(
        sys.argv,
        expected=3,
        usage="python3 image_processing.py <root_path> <rat> <group>",
    )

    root_path = Path(sys.argv[1])
    rat_id = sys.argv[2]
    group_id = sys.argv[3]

    if not root_path.is_dir():
        log.error(f"Root path not found: {root_path}")
        sys.exit(1)

    b_in, m_in, b_out, m_out = _build_paths(root_path, rat_id, group_id)

    try:
        slice_rotate_and_mask(OP_SILVIA, b_in, m_in, b_out, m_out)
        log.info("image_processing completed successfully.")
    except (ValidationError, ValueError, FileNotFoundError) as exc:
        log.error(f"Processing failed: {exc}")
        sys.exit(1)
