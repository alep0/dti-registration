#!/usr/bin/env bash
# =============================================================================
# resample_standard.sh
# ─────────────────────────────────────────────────────────────────────────────
# Resample a standard-space NIfTI image to a lower resolution using ANTs
# ResampleImage, producing a file ready for the slicing/registration pipeline.
#
# Usage:
#   ./source/analysis/resample_standard.sh <file_stem> <root_path>
#
# Arguments:
#   file_stem  - Stem of the input file, e.g. "brain10" or "atlas10"
#                (expects <file_stem>.nii.gz in data/standard/)
#   root_path  - Absolute path to the project root directory
#
# Outputs:
#   results/pre/sliced_3d_masked/Standard_scaled_r/256/<file_stem>_r.nii.gz
#
# Replaces: resampling_standard_v4.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=2
readonly IMAGE_DIM=3
readonly OUTPUT_SIZE="128x256x128"
readonly INTERP_TYPE=1
readonly INTERP_METHOD=2

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

# ── Argument validation ────────────────────────────────────────────────────────
if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <file_stem> <root_path>" >&2
    exit 1
fi

FILE_STEM="$1"
ROOT_PATH="$2"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

# ── Logging init ──────────────────────────────────────────────────────────────
LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/resample_standard_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Starting resampling for: ${FILE_STEM}"
log_info "Root: ${ROOT_PATH}"

# ── Tool check ────────────────────────────────────────────────────────────────
if ! command -v ResampleImage &>/dev/null; then
    log_error "ResampleImage not found. Install ANTs and activate the conda env."
    exit 1
fi
log_info "ResampleImage found."

# ── Paths ─────────────────────────────────────────────────────────────────────
INPUT_DIR="${ROOT_PATH}/data/standard"
OUTPUT_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/Standard_scaled_r/256"

INPUT_FILE="${INPUT_DIR}/${FILE_STEM}.nii.gz"
OUTPUT_FILE="${OUTPUT_DIR}/${FILE_STEM}_r.nii.gz"

log_info "Input:  ${INPUT_FILE}"
log_info "Output: ${OUTPUT_FILE}"

# ── Input validation ──────────────────────────────────────────────────────────
if [[ ! -f "${INPUT_FILE}" ]]; then
    log_error "Input file not found: ${INPUT_FILE}"
    exit 1
fi
log_info "Input file validated."

# ── Output directory ──────────────────────────────────────────────────────────
mkdir -p "${OUTPUT_DIR}"
log_info "Output directory ready: ${OUTPUT_DIR}"

# ── Resample ──────────────────────────────────────────────────────────────────
log_info "Running ResampleImage (output size=${OUTPUT_SIZE}) ..."
ResampleImage \
    "${IMAGE_DIM}" \
    "${INPUT_FILE}" \
    "${OUTPUT_FILE}" \
    "${OUTPUT_SIZE}" \
    "${INTERP_TYPE}" \
    "${INTERP_METHOD}"

if [[ ! -f "${OUTPUT_FILE}" ]]; then
    log_error "Resampled file was not created: ${OUTPUT_FILE}"
    exit 1
fi

log_info "Resampling completed successfully."
log_info "Output: ${OUTPUT_FILE}"
