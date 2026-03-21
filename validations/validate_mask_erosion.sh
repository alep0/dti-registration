#!/usr/bin/env bash
# =============================================================================
# validate_mask_erosion.sh
# ─────────────────────────────────────────────────────────────────────────────
# Validation tests for source/analysis/mask_erosion.sh
#
# Tests:
#   1. Wrong number of parameters
#   2. Non-existent root path
#   3. FSL not installed (fslmaths unavailable)
#   4. Correct execution (requires FSL + valid data)
#   5. Wrong input data filename
#
# Usage:
#   ./validations/validate_mask_erosion.sh <root_path>
#
# Replaces: test_fslerosion_v6_c3.md (manual steps → automated checks)
# =============================================================================

set -uo pipefail

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT="$(dirname "$0")/../source/analysis/mask_erosion.sh"
PASS=0
FAIL=0

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
pass() { log "[PASS] $1"; ((PASS++)) || true; }
fail() { log "[FAIL] $1"; ((FAIL++)) || true; }

# ── Arg check ────────────────────────────────────────────────────────────────
if [[ $# -ne 1 ]]; then
    echo "Usage: ${SCRIPT_NAME} <root_path>"
    exit 1
fi
ROOT_PATH="$1"

log "=== Validating mask_erosion.sh ==="

# ── Test 1: Wrong number of parameters ───────────────────────────────────────
log "Test 1: Wrong number of parameters"
if bash "${SCRIPT}" "t1" "R01" 2>&1 | grep -qi "error"; then
    pass "Test 1"
else
    fail "Test 1 – expected error for wrong arg count"
fi

# ── Test 2: Non-existent root path ───────────────────────────────────────────
log "Test 2: Non-existent root path"
if bash "${SCRIPT}" "t1" "R01" "/nonexistent/path_xyz_$(date +%s)" 2>&1 | grep -qi "error"; then
    pass "Test 2"
else
    fail "Test 2 – expected error for bad root path"
fi

# ── Test 3: fslmaths unavailable ─────────────────────────────────────────────
log "Test 3: fslmaths not in PATH"
OLD_PATH="${PATH}"
PATH="$(echo "${PATH}" | tr ':' '\n' | grep -iv 'fsl' | paste -sd':')"
export PATH
if bash "${SCRIPT}" "t1" "R01" "${ROOT_PATH}" 2>&1 | grep -qi "error\|not found"; then
    pass "Test 3"
else
    fail "Test 3 – expected error when fslmaths is absent"
fi
export PATH="${OLD_PATH}"

# ── Test 4: Correct execution ─────────────────────────────────────────────────
log "Test 4: Proper execution with valid data"
if command -v fslmaths &>/dev/null; then
    MASK_DIR="${ROOT_PATH}/data/nifti/t1"
    OUT_DIR="${ROOT_PATH}/results/pre/t1/R01"
    if [[ -f "${MASK_DIR}/R01_HARDI_mask.nii" ]]; then
        mkdir -p "${OUT_DIR}"
        if bash "${SCRIPT}" "t1" "R01" "${ROOT_PATH}" 2>&1 | grep -qi "completed\|success"; then
            pass "Test 4"
        else
            fail "Test 4 – script did not report success"
        fi
    else
        log "[SKIP] Test 4 – data file not found: ${MASK_DIR}/R01_HARDI_mask.nii"
    fi
else
    log "[SKIP] Test 4 – fslmaths not available in this environment"
fi

# ── Test 5: Wrong input data filename ─────────────────────────────────────────
log "Test 5: Input file does not exist (wrong rat ID)"
if bash "${SCRIPT}" "t1" "R99_WRONG" "${ROOT_PATH}" 2>&1 | grep -qi "error\|not found"; then
    pass "Test 5"
else
    fail "Test 5 – expected error for non-existent input"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
log "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]]
