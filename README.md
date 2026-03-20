# DTI Rat Brain Registration Pipeline

[![CI](https://github.com/aaaguado/dti-registration/actions/workflows/ci.yml/badge.svg)](https://github.com/aaaguado/dti-registration/actions)
[![Python](https://img.shields.io/badge/python-3.10%2B-blue)](https://www.python.org/)

Robust, reproducible pipeline for preparing experimental rat-brain DTI data (18 rats, control + alcoholic groups) for connectome fibre reconstruction.

**Full documentation → [docs/README.md](docs/README.md)**

## 60-second start

```bash
git clone https://github.com/aaaguado/dti-registration.git && cd dti-registration
conda env create -f config/environment.yml && conda activate dti-registration
# Place data under data/ – see docs/QUICKSTART.md
./run_full_pipeline.sh 1 "R01 R02" /absolute/path/to/dti-registration
```

## Key docs

| | |
|---|---|
| [QUICKSTART](docs/QUICKSTART.md) | Step-by-step usage |
| [Installation](docs/installation.md) | All dependencies |
| [API reference](docs/api.md) | Python module docs |
| [Docker](docs/Docker.md) | Containerised run |
| [GitHub / CI](docs/GitHub.md) | Contributing |
