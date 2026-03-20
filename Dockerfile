# ─────────────────────────────────────────────────────────────────────────────
# DTI Rat Brain Registration Pipeline – Dockerfile
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04

LABEL maintainer="aaaguado@ifisc.uib-csic.es"
LABEL version="1.0.0"
LABEL description="DTI rat brain registration pipeline: atlas warping and connectome prep"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget curl ca-certificates \
        python3 python3-pip python3-venv \
        bash shellcheck \
        bc dc \
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# ── Miniconda (for ANTs and Python environment) ───────────────────────────────
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
        -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p "${CONDA_DIR}" \
    && rm /tmp/miniconda.sh
ENV PATH="${CONDA_DIR}/bin:${PATH}"

# ── Create conda environment from config/environment.yml ─────────────────────
COPY config/environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml \
    && conda clean -afy

# Activate the environment by default
ENV CONDA_DEFAULT_ENV=dti-registration
ENV PATH="${CONDA_DIR}/envs/dti-registration/bin:${PATH}"

# ── FSL installation ──────────────────────────────────────────────────────────
# FSL 6.0 – installs to /usr/local/fsl by default
ENV FSLDIR=/usr/local/fsl
RUN wget --quiet https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py \
        -O /tmp/fslinstaller.py \
    && python3 /tmp/fslinstaller.py -d "${FSLDIR}" -q \
    && rm /tmp/fslinstaller.py

# Make FSL available in all shells
RUN echo "source ${FSLDIR}/etc/fslconf/fsl.sh" >> /etc/profile.d/fsl.sh
ENV PATH="${FSLDIR}/bin:${PATH}"
ENV FSLOUTPUTTYPE=NIFTI_GZ

# ── Project files ─────────────────────────────────────────────────────────────
WORKDIR /workspace
COPY . /workspace/

# Make all shell scripts executable
RUN find /workspace -name "*.sh" -exec chmod +x {} \;

# Create required directories
RUN mkdir -p /workspace/data /workspace/results /workspace/logs

# ── Health check ──────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD \
    python3 -c "import dipy, numpy; print('OK')" && \
    command -v antsRegistrationSyN.sh && \
    command -v fslmaths

# ── Default command ───────────────────────────────────────────────────────────
CMD ["bash"]
