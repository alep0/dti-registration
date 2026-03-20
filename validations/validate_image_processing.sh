#!/usr/bin/env bash
# =============================================================================
# validate_image_processing.sh
# ─────────────────────────────────────────────────────────────────────────────
# End-to-end validation of source/core/image_processing.py via CLI.
#
# Tests:
#   1. Wrong number of arguments
#   2. Non-existent root path
#   3. Python environment not activated (dipy missing)
#   4. Wrong input filename (rat not found in data)
#   5. Proper execution with valid data
#
# Usage:
#   ./validations/validate_image_processing.sh <root_path>
#
# Replaces: test_standard_rats_engine_v8_c0.md (manual → automated)
# =============================================================================

set -uo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
PASS=0
FAIL=0

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
pass() { log "[PASS] $1"; ((PASS++)) || true; }
fail() { log "[FAIL] $1"; ((FAIL++)) || true; }

if [[ $# -ne 1 ]]; then
    echo "Usage: ${SCRIPT_NAME} <root_path>"
    exit 1
fi
ROOT_PATH="$1"

MODULE="source.core.image_processing"
log "=== Validating image_processing.py ==="

# ── Test 1: Wrong number of arguments ────────────────────────────────────────
log "Test 1: Wrong number of arguments"
if PYTHONPATH="${ROOT_PATH}" python3 -m "${MODULE}" 2>&1 | grep -qi "usage\|error\|expected"; then
    pass "Test 1"
else
    fail "Test 1 – expected usage/error message for missing args"
fi

# ── Test 2: Non-existent root path ───────────────────────────────────────────
log "Test 2: Non-existent root path"
if PYTHONPATH="${ROOT_PATH}" python3 -m "${MODULE}" \
        "/nonexistent/path_xyz" "R01" "t1" 2>&1 | grep -qi "error\|not found"; then
    pass "Test 2"
else
    fail "Test 2 – expected error for bad root path"
fi

# ── Test 3: dipy not available ───────────────────────────────────────────────
log "Test 3: dipy import failure (deactivated env)"
if ! python3 -c "import dipy" &>/dev/null; then
    if PYTHONPATH="${ROOT_PATH}" python3 -m "${MODULE}" \
            "${ROOT_PATH}" "R01" "t1" 2>&1 | grep -qi "error\|ModuleNotFound"; then
        pass "Test 3"
    else
        fail "Test 3 – expected ImportError when dipy absent"
    fi
else
    log "[SKIP] Test 3 – dipy is available (conda env active)"
fi

# ── Test 4: Wrong input filename ─────────────────────────────────────────────
log "Test 4: Non-existent input file (bad rat ID)"
if PYTHONPATH="${ROOT_PATH}" python3 -m "${MODULE}" \
        "${ROOT_PATH}" "R99_WRONG" "t1" 2>&1 | grep -qi "error\|not found"; then
    pass "Test 4"
else
    fail "Test 4 – expected error for missing input file"
fi

# ── Test 5: Proper execution ──────────────────────────────────────────────────
log "Test 5: Proper execution with valid data"
DATA_FILE="${ROOT_PATH}/data/nifti/t1/R01_HARDI.nii"
if python3 -c "import dipy" &>/dev/null && [[ -f "${DATA_FILE}" ]]; then
    if PYTHONPATH="${ROOT_PATH}" python3 -m "${MODULE}" \
            "${ROOT_PATH}" "R01" "t1" 2>&1 | grep -qi "completed\|saved\|success"; then
        pass "Test 5"
    else
        fail "Test 5 – did not find success message in output"
    fi
else
    log "[SKIP] Test 5 – dipy unavailable or data missing: ${DATA_FILE}"
fi

log "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]]
