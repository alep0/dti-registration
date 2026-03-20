# QUICKSTART

This guide walks you from a fresh checkout to a fully processed dataset.

---

## 0. Prerequisites

- Linux (Ubuntu 20.04+ recommended) or WSL2
- Conda (Miniconda or Anaconda)
- ANTs (installed via conda – see step 1)
- FSL (installed separately – see step 1)
- Matlab R2023b + ExploreDTI (for motion correction – manual step)

---

## 1. Installation

### Clone the repository

```bash
git clone https://github.com/aaaguado/dti-registration.git
cd dti-registration
```

### Option A – Conda (recommended)

```bash
conda env create -f config/environment.yml
conda activate dti-registration
```

This installs Python 3.10, NumPy, Dipy, ANTs, and all other Python dependencies.

### Option B – Docker (no local install required)

```bash
docker compose up --build
```

See [Docker.md](Docker.md) for details.

### Install FSL separately

FSL is not available via conda and must be installed manually:

```bash
wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
python3 fslinstaller.py   # follow interactive prompts
source ~/.bashrc
```

---

## 2. Data layout

Place your input data as follows:

```
data/
├── standard/
│   ├── brain10.nii.gz          # WHS standard rat brain
│   └── atlas10.nii.gz          # WHS atlas
├── nifti/
│   ├── t1/                     # Group 1 (control)
│   │   ├── R01_HARDI.nii
│   │   ├── R01_HARDI_mask.nii
│   │   └── ...
│   └── t2/                     # Group 2 (alcoholic)
│       └── ...
├── maps/
│   ├── t1/  (AX_1R01.nii, FM_1R01.nii, FR_1R01.nii, MF_1R01.nii, ...)
│   └── t2/
└── tract/
    ├── t1/  (R01_HARDI.mat, ...)
    └── t2/
```

---

## 3. Motion correction (Matlab – manual step)

Open **MATLAB R2023b** and launch **ExploreDTI**:

```
MainExploreDTI
```

For each rat in each group:

1. **Motion correction**
   - `Plugins → Correct for subject motion and EC/EPI distortions`
   - Input:  `data/tract/<group>/R*_HARDI.mat`
   - Output: `results/pre/matlab/<group>/R*_HARDI_MD_C_native.mat`

2. **Export DWIs**
   - `Plugins → Export stuff to *.nii files (DWIs with B0s _DWIs.nii)`
   - Input:  `results/pre/matlab/<group>/R*_HARDI_MD_C_native.mat`
   - Output: `results/pre/matlab/<group>/R*_HARDI_MD_C_native_DWIs.nii`

3. **Export bval/bvec**
   - `Plugins → Convert (B-matrix in DTI *.mat to *.bval/*.bvec)`
   - Input:  `results/pre/matlab/<group>/R*_HARDI_MD_C_native.mat`
   - Output: `results/pre/matlab/<group>/R*_HARDI_MD_C_native.bval/.bvec`

---

## 4. Run the pipeline

### Full pipeline (recommended)

```bash
conda activate dti-registration
./run_full_pipeline.sh 1 "R01 R02 R03" /absolute/path/to/dti-registration
```

Replace `1` with `2` for group t2, and list the rat IDs you want to process.

### Step-by-step (individual modules)

```bash
# Registration only
./run_registration.sh t1 "R01 R02" /path/to/project

# Format + stage only (after Matlab and registration)
./run_format.sh 1 "R01 R02" /path/to/project
```

---

## 5. Inspect outputs

```bash
# Check a registered atlas overlaid on a DWI volume (requires FSLeyes)
conda activate dti-registration
fsleyes results/t1/R01/t1_atlas_s_awarped_R01.nii.gz \
         results/t1/R01/R01_HARDI_MD_C_native_DWIs.nii
```

---

## 6. Run tests

```bash
conda activate dti-registration
pytest validations/ -v --tb=short
```

---

## 7. View logs

All log files are written to `logs/` with timestamps:

```bash
ls logs/
tail -f logs/run_full_pipeline_*.log
```
