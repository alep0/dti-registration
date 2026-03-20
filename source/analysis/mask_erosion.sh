#!/usr/bin/env bash
# =============================================================================
# mask_erosion.sh
# ─────────────────────────────────────────────────────────────────────────────
# Erode the outer ring of a binary brain mask using FSL fslmaths.
#
# Usage:
#   ./source/analysis/mask_erosion.sh <group> <rat> <root_path>
#
# Arguments:
#   group      - Scan group, e.g. "t1" or "t2"
#   rat        - Rat identifier, e.g. "R01"
#   root_path  - Absolute path to the project root directory
#
# Outputs:
#   results/pre/<group>/<rat>/<rat>_HARDI_mask_eroded.nii.gz
#
# Replaces: fslerosion.sh (v6_c3)
# =============================================================================

set -euo pipefail

# ── Constants ─────────────────────────────────────────────────────────────────
readonly SCRIPT_NAME="$(basename "$0")"
readonly REQUIRED_ARGS=3

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE" >&2; }
log_warn()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]  ${SCRIPT_NAME}: $*" | tee -a "$LOG_FILE"; }

# ── Argument validation ────────────────────────────────────────────────────────
if [[ $# -ne ${REQUIRED_ARGS} ]]; then
    echo "Error: Expected ${REQUIRED_ARGS} arguments, got $#." >&2
    echo "Usage: ${SCRIPT_NAME} <group> <rat> <root_path>" >&2
    exit 1
fi

GROUP="$1"
RAT="$2"
ROOT_PATH="$3"

# ── Root path validation ───────────────────────────────────────────────────────
if [[ ! -d "${ROOT_PATH}" ]]; then
    echo "Error: Root path does not exist: ${ROOT_PATH}" >&2
    exit 1
fi

# ── Initialise logging ────────────────────────────────────────────────────────
LOG_DIR="${ROOT_PATH}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/mask_erosion_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Starting mask erosion."
log_info "Group: ${GROUP} | Rat: ${RAT} | Root: ${ROOT_PATH}"

# ── Tool check ────────────────────────────────────────────────────────────────
if ! command -v fslmaths &>/dev/null; then
    log_error "fslmaths not found in PATH. Install FSL and source fsl.sh."
    exit 1
fi
log_info "fslmaths: $(command -v fslmaths)"

# ── Derive paths ──────────────────────────────────────────────────────────────
DATA_PATH="${ROOT_PATH}/data/nifti/${GROUP}"
OUT_PATH="${ROOT_PATH}/results/pre/${GROUP}/${RAT}"
CONFIG_PATH="${ROOT_PATH}/config/config.json"

MASK_IN="${DATA_PATH}/${RAT}_HARDI_mask.nii"
MASK_OUT="${OUT_PATH}/${RAT}_HARDI_mask_eroded.nii.gz"

log_info "Input mask:  ${MASK_IN}"
log_info "Output mask: ${MASK_OUT}"

# ── Input file validation ─────────────────────────────────────────────────────
if [[ ! -f "${MASK_IN}" ]]; then
    log_error "Input mask not found: ${MASK_IN}"
    exit 1
fi
log_info "Input mask validated."

# ── Output directory ──────────────────────────────────────────────────────────
mkdir -p "${OUT_PATH}"
log_info "Output directory ready: ${OUT_PATH}"

# ── Run erosion ───────────────────────────────────────────────────────────────
log_info "Running: fslmaths ${MASK_IN} -ero ${MASK_OUT}"
fslmaths "${MASK_IN}" -ero "${MASK_OUT}"

if [[ ! -f "${MASK_OUT}" ]]; then
    log_error "Output file was not created: ${MASK_OUT}"
    exit 1
fi

log_info "Mask erosion completed successfully."
log_info "Output: ${MASK_OUT}"
