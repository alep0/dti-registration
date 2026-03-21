#!/usr/bin/env bash
# =============================================================================
# stage_results.sh
# ─────────────────────────────────────────────────────────────────────────────
# Copy all pipeline outputs for one or more rats into a clean, structured
# results directory ready for the connectome reconstruction stage.
#
# Usage:
#   ./source/analysis/stage_results.sh <group_index> "<rat_list>" <root_path>
#
# Arguments:
#   group_index - Numeric group index (1 = control/t1, 2 = alcoholic/t2)
#   rat_list    - Space-separated rat IDs in quotes, e.g. "R01 R02"
#   root_path   - Absolute path to the project root directory
#
# Replaces: copy_v0.sh, format_v0.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=3

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }

_copy_file() {
    local src="$1" dst="$2"
    if [[ ! -f "${src}" ]]; then
        log_warn "Source not found, skipping: ${src}"
        return
    fi
    cp "${src}" "${dst}"
    log_info "  Copied: $(basename "${src}")"
}

_move_file() {
    local src="$1" dst="$2"
    if [[ ! -f "${src}" ]]; then
        log_warn "Source not found, skipping: ${src}"
        return
    fi
    mv "${src}" "${dst}"
    log_info "  Moved:  $(basename "${src}")"
}

if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <group_index> \"<rat_list>\" <root_path>" >&2
    exit 1
fi

GROUP_IDX="$1"
RATS="$2"
ROOT_PATH="$3"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

GROUP="t${GROUP_IDX}"

LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/stage_results_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Staging results. Group: ${GROUP} | Rats: ${RATS}"

for RAT in ${RATS}; do
    log_info "Staging rat: ${RAT}"

    PRE_DIR="${ROOT_PATH}/results/pre/${GROUP}/${RAT}"
    MATLAB_DIR="${ROOT_PATH}/results/pre/matlab/${GROUP}"
    MAPS_DIR="${ROOT_PATH}/data/maps/${GROUP}"
    OUT_DIR="${ROOT_PATH}/results/${GROUP}/${RAT}"
    MAPS_OUT="${OUT_DIR}/maps_nifti"

    mkdir -p "${OUT_DIR}" "${MAPS_OUT}"
    log_info "  Output directory: ${OUT_DIR}"

    # ── Registration outputs ────────────────────────────────────────────────
    _copy_file \
        "${PRE_DIR}/${RAT}_HARDI_mask_eroded.nii.gz" \
        "${OUT_DIR}/${RAT}_HARDI_mask_eroded.nii.gz"

    _copy_file \
        "${PRE_DIR}/${GROUP}_atlas_s_awarped_${RAT}.nii.gz" \
        "${OUT_DIR}/${GROUP}_atlas_s_awarped_${RAT}.nii.gz"

    # ── DWI output ─────────────────────────────────────────────────────────
    _copy_file \
        "${MATLAB_DIR}/${RAT}_HARDI_MD_C_native_DWIs.nii" \
        "${OUT_DIR}/${RAT}_HARDI_MD_C_native_DWIs.nii"

    # ── bval / bvec (move to avoid duplicates) ─────────────────────────────
    _move_file \
        "${MATLAB_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bval.txt" \
        "${OUT_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bval.txt"

    _move_file \
        "${MATLAB_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bvec.txt" \
        "${OUT_DIR}/${RAT}_${GROUP}_HARDI_MD_C_native_bvec.txt"

    # ── Quantitative maps ───────────────────────────────────────────────────
    for PREFIX in AX FM FR MF; do
        _copy_file \
            "${MAPS_DIR}/${PREFIX}_${GROUP_IDX}${RAT}.nii" \
            "${MAPS_OUT}/${PREFIX}_${GROUP_IDX}${RAT}.nii"
    done

    log_info "Rat ${RAT} staged successfully."
done

log_info "All rats staged. Results directory: ${ROOT_PATH}/results/${GROUP}/"
