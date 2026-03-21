#!/usr/bin/env bash
# =============================================================================
# slice_standard_brain.sh
# ─────────────────────────────────────────────────────────────────────────────
# Slice, reorient, and skull-strip the WHS standard-rat brain + atlas NIfTIs.
# Delegates computation to source/core/image_processing.py.
#
# Usage:
#   ./source/analysis/slice_standard_brain.sh <root_path>
#
# Replaces: slacing_standard_v4.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=1
#readonly OP_STANDARD=2

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} argument, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <root_path>" >&2
    exit 1
fi

ROOT_PATH="$1"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/slice_standard_brain_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Slicing WHS standard-rat brain."
log_info "Root: ${ROOT_PATH}"

STD_SCALED="${ROOT_PATH}/results/pre/sliced_3d_masked/Standard_scaled_r/256"

BRAIN_IN="${STD_SCALED}/brain10_r.nii.gz"
ATLAS_IN="${STD_SCALED}/atlas10_r.nii.gz"
BRAIN_OUT="${STD_SCALED}/syn_b02m_z256_s_std_ix.nii.gz"
ATLAS_OUT="${STD_SCALED}/syn_b02_m_z256_s_std_ix.nii.gz"

log_info "Brain in:  ${BRAIN_IN}"
log_info "Atlas in:  ${ATLAS_IN}"
log_info "Brain out: ${BRAIN_OUT}"
log_info "Atlas out: ${ATLAS_OUT}"

for f in "${BRAIN_IN}" "${ATLAS_IN}"; do
    if [[ ! -f "${f}" ]]; then
        log_error "Input not found: ${f}"
        exit 1
    fi
done

log_info "Calling image_processing.py for standard rat ..."
PYTHONPATH="${ROOT_PATH}" python3 -c "
import sys
sys.path.insert(0, '${ROOT_PATH}')
from source.core.image_processing import slice_rotate_and_mask, OP_STANDARD
slice_rotate_and_mask(
    OP_STANDARD,
    '${BRAIN_IN}',
    '${ATLAS_IN}',
    '${BRAIN_OUT}',
    '${ATLAS_OUT}'
)
"

log_info "slice_standard_brain completed successfully."
