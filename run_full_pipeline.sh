#!/usr/bin/env bash
# =============================================================================
# run_full_pipeline.sh
# ─────────────────────────────────────────────────────────────────────────────
# Full end-to-end orchestrator: registration + format + staging.
#
# NOTE: The Matlab/ExploreDTI motion-correction step must be run manually
#       before executing this script. See docs/QUICKSTART.md for details.
#
# Usage:
#   ./run_full_pipeline.sh <group_index> "<rat_list>" <root_path>
#
# Example:
#   ./run_full_pipeline.sh 1 "R01 R02 R03" /data/Registration
#
# Replaces: registration_v0.sh + format_v0.sh combined
# =============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly REQUIRED_ARGS=3
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
LOG_FILE="${LOG_DIR}/run_full_pipeline_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "=========================================="
log_info " DTI Registration – Full Pipeline"
log_info " Group: ${GROUP} | Rats: ${RATS}"
log_info "=========================================="

log_info ">>> Phase 1: Registration"
bash "${SCRIPT_DIR}/run_registration.sh" "${GROUP}" "${RATS}" "${ROOT_PATH}"

log_info ">>> Phase 2: Format & Stage"
bash "${SCRIPT_DIR}/run_format.sh" "${GROUP_IDX}" "${RATS}" "${ROOT_PATH}"

log_info "=========================================="
log_info " Full pipeline completed successfully."
log_info " Results: ${ROOT_PATH}/results/${GROUP}/"
log_info "=========================================="
