#!/usr/bin/env bash
# =============================================================================
# run_format.sh
# ─────────────────────────────────────────────────────────────────────────────
# Orchestrator: convert bval/bvec files and stage all results for the
# connectome reconstruction stage.
#
# Usage:
#   ./run_format.sh <group_index> "<rat_list>" <root_path>
#
# Example:
#   ./run_format.sh 1 "R01 R02" /data/Registration
#
# Replaces: format_v0.sh
# =============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly REQUIRED_ARGS=3

log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }

if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <group_index> \"<rat_list>\" <root_path>" >&2
    exit 1
fi

GROUP_IDX="$1"
RATS="$2"
ROOT_PATH="$3"
GROUP="t${GROUP_IDX}"

if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/run_format_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

ANALYSIS="${ROOT_PATH}/source/analysis"

log_info "=== Format + Stage Pipeline Start ==="
log_info "Group: ${GROUP} | Rats: ${RATS}"

log_info "--- Step 1: Converting bval/bvec to txt ---"
bash "${ANALYSIS}/convert_bval_bvec.sh" "${GROUP}" "${RATS}" "${ROOT_PATH}"

log_info "--- Step 2: Staging results for connectome stage ---"
bash "${ANALYSIS}/stage_results.sh" "${GROUP_IDX}" "${RATS}" "${ROOT_PATH}"

log_info "=== Format + Stage Pipeline Complete ==="
