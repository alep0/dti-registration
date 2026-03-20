#!/usr/bin/env bash
# =============================================================================
# run_registration.sh
# ─────────────────────────────────────────────────────────────────────────────
# Orchestrator: run the full registration pipeline for one or more rats.
# Steps executed:
#   1. Resample the WHS standard brain and atlas.
#   2. Slice + reorient the standard brain/atlas.
#   3. For each rat: slice + reorient, then run ANTs SyN registration.
#   4. For each rat: erode mask and apply atlas warp.
#
# Usage:
#   ./run_registration.sh <group> "<rat_list>" <root_path>
#
# Example:
#   ./run_registration.sh t1 "R01 R02 R03" /data/Registration
#
# Replaces: registration_v0.sh
# =============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly REQUIRED_ARGS=3
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
LOG_FILE="${LOG_DIR}/run_registration_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

ANALYSIS="${ROOT_PATH}/source/analysis"

log_info "=== DTI Registration Pipeline Start ==="
log_info "Group: ${GROUP} | Rats: ${RATS}"

# ── Step 1 & 2: Standard brain resampling and slicing ────────────────────────
log_info "--- Step 1: Resampling standard brain and atlas ---"
bash "${ANALYSIS}/resample_standard.sh" brain10 "${ROOT_PATH}"
bash "${ANALYSIS}/resample_standard.sh" atlas10  "${ROOT_PATH}"

log_info "--- Step 2: Slicing standard brain ---"
bash "${ANALYSIS}/slice_standard_brain.sh" "${ROOT_PATH}"

# ── Step 3 & 4: Per-rat processing ───────────────────────────────────────────
for RAT in ${RATS}; do
    OUT_DIR="${ROOT_PATH}/results/pre/${GROUP}/${RAT}"
    mkdir -p "${OUT_DIR}"

    log_info "--- Processing rat: ${RAT} ---"

    log_info "  Step 3a: Slicing rat brain (${RAT})"
    bash "${ANALYSIS}/slice_rat_brain.sh" "${GROUP}" "${RAT}" "${ROOT_PATH}"

    log_info "  Step 3b: ANTs SyN registration (${RAT})"
    bash "${ANALYSIS}/ants_registration.sh" "${GROUP}" "${RAT}" "${ROOT_PATH}"

    log_info "  Step 4a: Mask erosion (${RAT})"
    bash "${ANALYSIS}/mask_erosion.sh" "${GROUP}" "${RAT}" "${ROOT_PATH}"

    log_info "  Step 4b: Applying atlas warp (${RAT})"
    bash "${ANALYSIS}/apply_warp.sh" "${GROUP}" "${RAT}" "${ROOT_PATH}"

    log_info "  Rat ${RAT} completed."
done

log_info "=== DTI Registration Pipeline Complete ==="
