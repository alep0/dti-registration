#!/usr/bin/env bash
# =============================================================================
# apply_warp.sh
# ─────────────────────────────────────────────────────────────────────────────
# Apply pre-computed ANTs transforms (affine + inverse warp) to carry the
# standard-rat atlas into each individual Silvia-rat space.
#
# Usage:
#   ./source/analysis/apply_warp.sh <group> <rat> <root_path>
#
# Arguments:
#   group      - Scan group, e.g. "t1" or "t2"
#   rat        - Rat identifier, e.g. "R01"
#   root_path  - Absolute path to the project root directory
#
# Outputs:
#   results/pre/<group>/<rat>/<group>_atlas_s_awarped_<rat>.nii.gz
#
# Replaces: ants_warp_v1.sh
# =============================================================================

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
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
LOG_FILE="${LOG_DIR}/apply_warp_$(date +%Y%m%d_%H%M%S).log"
touch "${LOG_FILE}"

log_info "Starting atlas warping."
log_info "Group: ${GROUP} | Rat: ${RAT} | Root: ${ROOT_PATH}"

# ── Tool check ────────────────────────────────────────────────────────────────
if ! command -v WarpImageMultiTransform &>/dev/null; then
    log_error "WarpImageMultiTransform not found. Install ANTs and activate conda env."
    exit 1
fi
log_info "WarpImageMultiTransform found."

# ── Paths ─────────────────────────────────────────────────────────────────────
DIM=3

STD_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/Standard_scaled_r/256"
RAT_DIR="${ROOT_PATH}/results/pre/sliced_3d_masked/${GROUP}/${RAT}"
OUTPUT_DIR="${ROOT_PATH}/results/pre/${GROUP}/${RAT}"
TRANS_DIR="${ROOT_PATH}/results/pre/${GROUP}/Slices_3D_Masked_Scaled_Transposed_${RAT}_r"

FIXED_IMAGE="${STD_DIR}/syn_b02_m_z256_s_std_ix.nii.gz"
MOVING_IMAGE="${RAT_DIR}/${RAT}_syn_b02m_za_.nii.gz"
AFFINE="${TRANS_DIR}/0GenericAffine.mat"
INVERSE_WARP="${TRANS_DIR}/1InverseWarp.nii.gz"
OUTPUT="${OUTPUT_DIR}/${GROUP}_atlas_s_awarped_${RAT}.nii.gz"

log_info "Fixed image:    ${FIXED_IMAGE}"
log_info "Moving image:   ${MOVING_IMAGE}"
log_info "Affine:         ${AFFINE}"
log_info "Inverse warp:   ${INVERSE_WARP}"
log_info "Output:         ${OUTPUT}"

# ── Input validation ──────────────────────────────────────────────────────────
for f in "${FIXED_IMAGE}" "${MOVING_IMAGE}" "${AFFINE}" "${INVERSE_WARP}"; do
    if [[ ! -f "${f}" ]]; then
        log_error "Required input not found: ${f}"
        exit 1
    fi
done
log_info "All inputs validated."

# ── Output directory ──────────────────────────────────────────────────────────
mkdir -p "${OUTPUT_DIR}"

# ── Apply warp ────────────────────────────────────────────────────────────────
log_info "Running WarpImageMultiTransform (NN interpolation) ..."
WarpImageMultiTransform "${DIM}" \
    "${FIXED_IMAGE}" \
    "${OUTPUT}" \
    -R "${MOVING_IMAGE}" \
    -i "${AFFINE}" "${INVERSE_WARP}" \
    --use-NN

if [[ ! -f "${OUTPUT}" ]]; then
    log_error "Warped atlas was not created: ${OUTPUT}"
    exit 1
fi

log_info "Atlas warping completed successfully."
log_info "Warped atlas: ${OUTPUT}"
