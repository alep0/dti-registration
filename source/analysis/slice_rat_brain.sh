#!/usr/bin/env bash
# =============================================================================
# slice_rat_brain.sh
# ─────────────────────────────────────────────────────────────────────────────
# Slice, reorient, and skull-strip an individual Silvia-rat brain NIfTI.
# Delegates computation to source/core/image_processing.py.
#
# Usage:
#   ./source/analysis/slice_rat_brain.sh <group> <rat> <root_path>
#
# Arguments:
#   group      - Scan group, e.g. "t1" or "t2"
#   rat        - Rat identifier, e.g. "R01"
#   root_path  - Absolute path to the project root directory
#
# Replaces: slacing_rats_v4.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=3
#readonly OP_SILVIA=1

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

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

LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/slice_rat_brain_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Slicing rat brain: ${RAT} (${GROUP})"

DATA_DIR="${ROOT_PATH}/data/nifti/${GROUP}"
OUT_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/${GROUP}/${RAT}"
#SCRIPT_DIR="${ROOT_PATH}/source"

BRAIN_IN="${DATA_DIR}/${RAT}_HARDI.nii"
MASK_IN="${DATA_DIR}/${RAT}_HARDI_mask.nii"
BRAIN_OUT="${OUT_DIR}/${RAT}_syn_b02m_za_.nii.gz"
MASK_OUT="${OUT_DIR}/${RAT}_syn_b02_m_za_.nii.gz"

log_info "Brain in:  ${BRAIN_IN}"
log_info "Mask in:   ${MASK_IN}"
log_info "Brain out: ${BRAIN_OUT}"
log_info "Mask out:  ${MASK_OUT}"

for f in "${BRAIN_IN}" "${MASK_IN}"; do
    if [[ ! -f "${f}" ]]; then
        log_error "Input not found: ${f}"
        exit 1
    fi
done

mkdir -p "${OUT_DIR}"

log_info "Calling image_processing.py ..."
PYTHONPATH="${ROOT_PATH}" python3 -m source.core.image_processing \
    "${ROOT_PATH}" "${RAT}" "${GROUP}"

log_info "slice_rat_brain completed for ${RAT}."
