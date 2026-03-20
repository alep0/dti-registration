# Installation

## System requirements

| Component | Minimum version | Notes |
|---|---|---|
| Linux / WSL2 | Ubuntu 20.04+ | macOS untested |
| Python | 3.10 | Managed via conda |
| Conda | 23.x | Miniconda or Anaconda |
| ANTs | 0.3+ | Installed via conda |
| FSL | 6.0+ | Installed separately |
| Matlab | R2023b | Motion correction (manual step) |
| ExploreDTI | latest | Matlab plugin |
| Docker | 24.x | Optional containerised run |

---

## Step 1 – Install Conda

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
source ~/.bashrc
conda --version
```

---

## Step 2 – Create the Python environment

```bash
cd dti-registration
conda env create -f config/environment.yml
conda activate dti-registration
```

This installs:
- Python 3.10
- NumPy ≥ 1.23
- Dipy ≥ 1.7 (NIfTI I/O)
- ANTs ≥ 0.3 (registration + resampling + warp tools)
- pytest + pytest-cov (testing)

Verify the environment:

```bash
python3 -c "import dipy; print('dipy OK')"
antsRegistrationSyN.sh --help | head -5
ResampleImage --help | head -3
WarpImageMultiTransform --help | head -3
```

---

## Step 3 – Install FSL

FSL is not available from conda-forge and must be installed via the official installer.

```bash
wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
python3 fslinstaller.py
```

Follow the interactive prompts. After installation:

```bash
source ~/.bashrc
echo $FSLDIR          # should print /home/<user>/fsl or similar
fslmaths --help 2>&1 | head -3
```

If `fslmaths` is not found, add FSL to PATH manually:

```bash
export FSLDIR=/home/$USER/fsl
source $FSLDIR/etc/fslconf/fsl.sh
```

---

## Step 4 – Install ExploreDTI (Matlab)

1. Download from [exploredti.com/download](https://www.exploredti.com/download.htm).
2. Unzip `ExploreDTI_Matlab.zip` and add the folder to your Matlab path.
3. Launch with `MainExploreDTI` in the Matlab command window.

---

## Verifying the full installation

```bash
conda activate dti-registration
pytest validations/ -v
```

All tests should pass (data-dependent tests are skipped when data is absent).

---

## Updating the environment

```bash
conda activate dti-registration
conda env update -f config/environment.yml --prune
```
