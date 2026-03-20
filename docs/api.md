# API Reference

This document describes the public Python API exposed by `source/core/` and `source/utils/`.

---

## `source.core.image_processing`

### `slice_rotate_and_mask(operation, brain_path_in, mask_path_in, brain_path_out, mask_path_out)`

Slices, reorients, and skull-strips a NIfTI brain image.

**Parameters**

| Name | Type | Description |
|---|---|---|
| `operation` | `int` | `1` = Silvia (experimental) rat; `2` = WHS standard rat |
| `brain_path_in` | `str \| Path` | Input brain NIfTI (4-D for Silvia, 3-D for standard) |
| `mask_path_in` | `str \| Path` | Input binary mask NIfTI |
| `brain_path_out` | `str \| Path` | Output skull-stripped, reoriented brain |
| `mask_path_out` | `str \| Path` | Output reoriented mask |

**Raises**

- `ValidationError` – missing input files or shape mismatch
- `ValueError` – unsupported `operation` value

**Example**

```python
from source.core.image_processing import slice_rotate_and_mask, OP_SILVIA

slice_rotate_and_mask(
    OP_SILVIA,
    "data/nifti/t1/R01_HARDI.nii",
    "data/nifti/t1/R01_HARDI_mask.nii",
    "results/pre/sliced_3d_masked/t1/R01/R01_syn_b02m_za_.nii.gz",
    "results/pre/sliced_3d_masked/t1/R01/R01_syn_b02_m_za_.nii.gz",
)
```

**Constants**

| Name | Value | Description |
|---|---|---|
| `OP_SILVIA` | `1` | Silvia (experimental) rat operation |
| `OP_STANDARD` | `2` | WHS standard rat operation |

---

## `source.core.bvec_bval_converter`

### `convert_bval_bvec_to_txt(bval_in, bval_out, bvec_in, bvec_out)`

Converts ExploreDTI-format bval/bvec files to plain text, applying sign corrections for Matlab→Dipy coordinate convention.

**Parameters**

| Name | Type | Description |
|---|---|---|
| `bval_in` | `str \| Path` | Input `.bval` file |
| `bval_out` | `str \| Path` | Output `.txt` file for b-values |
| `bvec_in` | `str \| Path` | Input `.bvec` file |
| `bvec_out` | `str \| Path` | Output `.txt` file for gradient directions |

**Example**

```python
from source.core.bvec_bval_converter import convert_bval_bvec_to_txt

convert_bval_bvec_to_txt(
    "results/pre/matlab/t1/R01_HARDI_MD_C_native.bval",
    "results/pre/matlab/t1/R01_t1_HARDI_MD_C_native_bval.txt",
    "results/pre/matlab/t1/R01_HARDI_MD_C_native.bvec",
    "results/pre/matlab/t1/R01_t1_HARDI_MD_C_native_bvec.txt",
)
```

### `read_bval(bval_path) → list[float]`

Parse an ExploreDTI `.bval` file. Returns a Python list of floats.

### `read_bvec_with_sign_correction(bvec_path) → np.ndarray`

Parse an ExploreDTI `.bvec` file and apply sign corrections. Returns a `(33, 3)` array.

---

## `source.utils.config_loader`

### `load_config(config_path=None) → dict`

Load and validate `config/config.json`. Raises `ConfigError` on failure.

### `get(key_path, config=None, default=None)`

Retrieve a nested config value using dot-notation.

```python
from source.utils.config_loader import get
dim = get("registration.dimension")  # → 3
```

---

## `source.utils.validators`

### `require_file(path, label="File") → Path`

Assert that `path` exists and is a regular file. Raises `ValidationError` if not.

### `require_directory(path, label="Directory") → Path`

Assert that `path` exists and is a directory.

### `require_tool(tool) → str`

Assert that `tool` is on PATH (like `command -v`).

### `require_args(argv, expected, usage) → None`

Validate CLI argument count; exits with code 1 on mismatch.

### `ensure_directory(path) → Path`

Create `path` (and parents) if it does not exist.

---

## `source.utils.logger`

### `get_logger(name, logs_dir=None) → logging.Logger`

Return a named logger that writes simultaneously to stdout and to a timestamped log file in `logs/`.

```python
from source.utils.logger import get_logger
log = get_logger(__name__)
log.info("Pipeline started.")
```
