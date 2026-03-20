# DTI Rat Brain Registration Pipeline

A robust, reproducible pipeline for preparing experimental DTI rat-brain data for connectome reconstruction. Supports 18 rats across two groups (control and alcoholic), producing registered atlases, eroded masks, motion-corrected DWIs, and formatted bval/bvec files.

## Overview

This pipeline processes multi-shell HARDI data acquired from Silvia rats and registers a WHS standard-rat atlas into each individual rat's native space using ANTs SyN diffeomorphic registration. The outputs feed directly into the next stage of a broader connectome simulation project.

### What it produces

| Output file | Description |
|---|---|
| `<rat>_HARDI_mask_eroded.nii.gz` | Eroded binary brain mask |
| `<group>_atlas_s_awarped_<rat>.nii.gz` | Standard atlas warped to individual rat space |
| `<rat>_HARDI_MD_C_native_DWIs.nii` | Motion-corrected DWI volumes |
| `<rat>_<group>_HARDI_MD_C_native_bval.txt` | B-values (Dipy-ready) |
| `<rat>_<group>_HARDI_MD_C_native_bvec.txt` | Gradient directions (sign-corrected, Dipy-ready) |
| `AX/FM/FR/MF_<group><rat>.nii` | Quantitative microstructure maps |

## Quick start

```bash
# 1. Clone and set up the environment
git clone https://github.com/aaaguado/dti-registration.git
cd dti-registration
conda env create -f config/environment.yml
conda activate dti-registration

# 2. Place your data (see docs/QUICKSTART.md for data layout)

# 3. Run motion correction manually in Matlab/ExploreDTI (see docs/QUICKSTART.md)

# 4. Run the full pipeline
./run_full_pipeline.sh 1 "R01 R02 R03" /path/to/project
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the complete step-by-step guide.

## Documentation

| Document | Contents |
|---|---|
| [QUICKSTART.md](docs/QUICKSTART.md) | Step-by-step usage guide |
| [installation.md](docs/installation.md) | Dependency installation |
| [api.md](docs/api.md) | Python module reference |
| [Docker.md](docs/Docker.md) | Containerised execution |
| [GitHub.md](docs/GitHub.md) | Contributing and CI/CD |

## Project structure

```
dti-registration/
├── source/
│   ├── core/               # Python processing modules
│   │   ├── image_processing.py
│   │   └── bvec_bval_converter.py
│   ├── analysis/           # Bash orchestration scripts
│   │   ├── mask_erosion.sh
│   │   ├── ants_registration.sh
│   │   ├── apply_warp.sh
│   │   ├── resample_standard.sh
│   │   ├── slice_rat_brain.sh
│   │   ├── slice_standard_brain.sh
│   │   ├── convert_bval_bvec.sh
│   │   └── stage_results.sh
│   └── utils/              # Shared utilities
│       ├── logger.py
│       ├── config_loader.py
│       └── validators.py
├── data/                   # Input data (not tracked in Git)
├── results/                # Pipeline outputs (not tracked in Git)
├── validations/            # Test suite
├── config/
│   ├── config.json
│   └── environment.yml
├── docs/
├── logs/                   # Auto-generated log files
├── run_registration.sh     # Registration orchestrator
├── run_format.sh           # Format + stage orchestrator
├── run_full_pipeline.sh    # End-to-end orchestrator
├── Dockerfile
├── docker-compose.yml
└── .github/workflows/ci.yml
```

## Dependencies

- **ANTs** – diffeomorphic registration and resampling
- **FSL** – mask erosion (`fslmaths`)
- **Dipy** – NIfTI I/O
- **NumPy** – array processing
- **Matlab + ExploreDTI** – motion correction (manual step)

## Citation

If you use this pipeline, please cite:

> Aguado et al., *Delays* (in preparation). Contact: aaaguado@ifisc.uib-csic.es

## Acknowledgements

Funded by Maetzu / CSIC. Collaborators: Mirasso, Canals. Libraries: ANTs.
