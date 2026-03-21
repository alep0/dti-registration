#!/usr/bin/env bash
# =============================================================================
# ants_registration.sh
# ─────────────────────────────────────────────────────────────────────────────
# Compute the SyN diffeomorphic registration transform (affine + warp) from
# the standard rat brain space to an individual Silvia-rat space using ANTs.
#
# Usage:
#   ./source/analysis/ants_registration.sh <group> <rat> <root_path>
#
# Arguments:
#   group      - Scan group, e.g. "t1" or "t2"
#   rat        - Rat identifier, e.g. "R01"
#   root_path  - Absolute path to the project root directory
#
# Outputs (inside results/pre/<group>/Slices_3D_Masked_Scaled_Transposed_<rat>_r/):
#   0GenericAffine.mat
#   1Warp.nii.gz
#   1InverseWarp.nii.gz
#   Warped.nii.gz
#   InverseWarped.nii.gz
#
# Replaces: ants_reg_v4.sh
# Reference: https://kumisystems.dl.sourceforge.net/project/advants/Documentation/ants.pdf
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=3

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

# ── Argument validation ────────────────────────────────────────────────────────
if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <group> <rat> <root_path>" >&2
    exit 1
fi

GROUP="$1"
RAT="$2"
ROOT_PATH="$3"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

# ── Logging init ──────────────────────────────────────────────────────────────
LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/ants_registration_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Starting ANTs SyN registration."
log_info "Group: ${GROUP} | Rat: ${RAT} | Root: ${ROOT_PATH}"

# ── Tool check ────────────────────────────────────────────────────────────────
if ! command -v antsRegistrationSyN.sh &>/dev/null; then
    log_error "antsRegistrationSyN.sh not found. Install ANTs and activate the conda env."
    exit 1
fi
log_info "ANTs registration script found."

# ── Paths ─────────────────────────────────────────────────────────────────────
DIM=3
THREADS=10

FIXED_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/Standard_scaled_r/256"
MOVING_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/${GROUP}/${RAT}"
OUTPUT_DIR="${ROOT_PATH}/results/pre/${GROUP}/Slices_3D_Masked_Scaled_Transposed_${RAT}_r"

FIXED_IMAGE="${FIXED_DIR}/syn_b02m_z256_s_std_ix.nii.gz"
MOVING_IMAGE="${MOVING_DIR}/${RAT}_syn_b02m_za_.nii.gz"

log_info "Fixed image:  ${FIXED_IMAGE}"
log_info "Moving image: ${MOVING_IMAGE}"
log_info "Output dir:   ${OUTPUT_DIR}"

# ── Input validation ──────────────────────────────────────────────────────────
for f in "${FIXED_IMAGE}" "${MOVING_IMAGE}"; do
    if [[ ! -f "${f}" ]]; then
        log_error "Required input not found: ${f}"
        exit 1
    fi
done
log_info "Input images validated."

# ── Output directory ──────────────────────────────────────────────────────────
mkdir -p "${OUTPUT_DIR}"
log_info "Output directory ready: ${OUTPUT_DIR}"

# ── Run registration ──────────────────────────────────────────────────────────
log_info "Running antsRegistrationSyN.sh (transform=s, threads=${THREADS}) ..."
antsRegistrationSyN.sh \
    -d "${DIM}" \
    -n "${THREADS}" \
    -t s \
    -f "${FIXED_IMAGE}" \
    -m "${MOVING_IMAGE}" \
    -o "${OUTPUT_DIR}/"

# ── Output validation ─────────────────────────────────────────────────────────
for expected in "0GenericAffine.mat" "1Warp.nii.gz" "1InverseWarp.nii.gz"; do
    if [[ ! -f "${OUTPUT_DIR}/${expected}" ]]; then
        log_error "Expected output not found: ${OUTPUT_DIR}/${expected}"
        exit 1
    fi
done

log_info "ANTs registration completed successfully."
log_info "Transforms saved in: ${OUTPUT_DIR}"
