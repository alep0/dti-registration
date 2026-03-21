#!/usr/bin/env bash
# =============================================================================
# convert_bval_bvec.sh
# ─────────────────────────────────────────────────────────────────────────────
# Batch-convert ExploreDTI .bval/.bvec files to plain-text format (Dipy-ready)
# for one or more rats in a given group.
#
# Usage:
#   ./source/analysis/convert_bval_bvec.sh <group> "<rat_list>" <root_path>
#
# Arguments:
#   group      - Scan group, e.g. "t1" or "t2"
#   rat_list   - Space-separated rat IDs in quotes, e.g. "R01 R02 R03"
#   root_path  - Absolute path to the project root directory
#
# Replaces: bvalbvec2txt_v0.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=3

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <group> \"<rat_list>\" <root_path>" >&2
    exit 1
fi

GROUP="$1"
RATS="$2"
ROOT_PATH="$3"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/convert_bval_bvec_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Starting bval/bvec conversion. Group: ${GROUP} | Rats: ${RATS}"

MATLAB_DIR="${ROOT_PATH}/results/pre/matlab/${GROUP}"

for RAT in ${RATS}; do
    log_info "Processing rat: ${RAT}"

    BVAL_IN="${MATLAB_DIR}/${RAT}_HARDI_MD_C_native.bval"
    BVEC_IN="${MATLAB_DIR}/${RAT}_HARDI_MD_C_native.bvec"
    BVAL_OUT="${MATLAB_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bval.txt"
    BVEC_OUT="${MATLAB_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bvec.txt"

    log_info "  bval in:  ${BVAL_IN}"
    log_info "  bvec in:  ${BVEC_IN}"
    log_info "  bval out: ${BVAL_OUT}"
    log_info "  bvec out: ${BVEC_OUT}"

    for f in "${BVAL_IN}" "${BVEC_IN}"; do
        if [[ ! -f "${f}" ]]; then
            log_error "  Input not found: ${f}"
            exit 1
        fi
    done

    PYTHONPATH="${ROOT_PATH}" python3 -c "
import sys
sys.path.insert(0, '${ROOT_PATH}')
from source.core.bvec_bval_converter import convert_bval_bvec_to_txt
convert_bval_bvec_to_txt(
    '${BVAL_IN}', '${BVAL_OUT}',
    '${BVEC_IN}', '${BVEC_OUT}'
)
"
    log_info "  Converted: ${RAT}"
done

log_info "bval/bvec conversion completed for all rats."
