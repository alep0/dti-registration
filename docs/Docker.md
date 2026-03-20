# Docker

This project ships with a `Dockerfile` and `docker-compose.yml` for fully containerised execution. No local ANTs, FSL, or conda installation is required on the host.

> **Note:** The Matlab/ExploreDTI motion-correction step cannot run inside Docker and must be performed manually on the host before running the containerised pipeline. See [QUICKSTART.md](QUICKSTART.md) step 3.

---

## Quick start

### Build and run with Docker Compose

```bash
# Build the image
docker compose build

# Run the full pipeline for group t1, rats R01 and R02
docker compose run --rm pipeline \
    ./run_full_pipeline.sh 1 "R01 R02" /workspace
```

### Build manually

```bash
docker build -t dti-registration:1.0.0 .
```

### Run manually

```bash
docker run --rm \
    -v /path/to/your/data:/workspace/data:ro \
    -v /path/to/results:/workspace/results \
    -v /path/to/logs:/workspace/logs \
    dti-registration:1.0.0 \
    ./run_full_pipeline.sh 1 "R01 R02" /workspace
```

---

## Volume mounts

| Host path | Container path | Mode | Purpose |
|---|---|---|---|
| `./data` | `/workspace/data` | read-only | Input NIfTI, maps, tracts |
| `./results` | `/workspace/results` | read-write | Pipeline outputs |
| `./logs` | `/workspace/logs` | read-write | Log files |
| `./config` | `/workspace/config` | read-only | Configuration |

---

## Running tests inside Docker

```bash
docker compose run --rm pipeline pytest validations/ -v
```

---

## Image contents

- Base: `ubuntu:22.04`
- ANTs (via conda-forge)
- FSL 6.x
- Python 3.10 + Dipy + NumPy + pytest
- All pipeline scripts

---

## Rebuild after code changes

```bash
docker compose build --no-cache
```

---

## Troubleshooting

**FSL not found inside container**

Ensure `$FSLDIR` is set and fsl.sh is sourced. The Dockerfile does this automatically via `/etc/profile.d/fsl.sh`.

**Permission errors on output files**

Add `--user $(id -u):$(id -g)` to your `docker run` command, or use `docker compose` which inherits the host user.

**Out-of-memory during registration**

ANTs SyN registration is memory-intensive. Allocate at least 8 GB to Docker (Docker Desktop → Settings → Resources).
