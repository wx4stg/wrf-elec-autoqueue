#!/bin/bash
# Automated version of WRF-elec compile instructions for Texas Tech HPCC.
# Created 19 November 2026 by Sam Gardner <samuel.gardner@ttu.edu>

set -euo pipefail

EMAIL="${1:-}"

if [[ "$EMAIL" != *@* ]]; then
    echo "Usage: bash $(basename "$0") <YOUR EMAIL>" >&2
    exit 1
fi
if ! command -v sbatch > /dev/null; then
    echo "This script can only be run on SLURM based HPC platforms" >&2
    exit 1
fi

COMPILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compile"

# Submit a job and print its ID, or exit if submission fails
submit() {
    local jid
    jid=$(sbatch --parsable --mail-user="$EMAIL" "$@") || { echo "Failed to submit: $*" >&2; exit 1; }
    echo "${jid%%;*}"
}

echo "Submitting compile steps with dependencies..."

jid_clone=$(submit "$COMPILE_DIR/clone.scr") || exit 1
echo "Submitted clone.scr as Job ID $jid_clone"

jid_spack=$(submit --dependency=afterok:$jid_clone "$COMPILE_DIR/spack_ins.scr") || exit 1
echo "Submitted spack_ins.scr as Job ID $jid_spack"

jid_box=$(submit --dependency=afterok:$jid_spack "$COMPILE_DIR/boxcomp.scr") || exit 1
echo "Submitted boxcomp.scr as Job ID $jid_box"

jid_conf=$(submit --dependency=afterok:$jid_box "$COMPILE_DIR/wrfconf.scr") || exit 1
echo "Submitted wrfconf.scr as Job ID $jid_conf"

jid_ideal_comp=$(submit --dependency=afterok:$jid_conf --output=wrfcomp_em_quarter_ss.out --error=wrfcomp_em_quarter_ss.err "$COMPILE_DIR/wrfcomp.scr" em_quarter_ss) || exit 1
echo "Submitted wrfcomp.scr em_quarter_ss as Job ID $jid_ideal_comp"

jid_ideal=$(submit --dependency=afterok:$jid_ideal_comp "$COMPILE_DIR/ideal.scr") || exit 1
echo "Submitted ideal.scr as Job ID $jid_ideal"

jid_test=$(submit --dependency=afterok:$jid_ideal "$COMPILE_DIR/test-integ.scr") || exit 1
echo "Submitted test-integ.scr as Job ID $jid_test"

# em_real replaces main/wrf.exe, which the test run uses, so it has to wait for the test
jid_real_comp=$(submit --dependency=afterok:$jid_test --output=wrfcomp_em_real.out --error=wrfcomp_em_real.err "$COMPILE_DIR/wrfcomp.scr" em_real) || exit 1
echo "Submitted wrfcomp.scr em_real as Job ID $jid_real_comp"

jid_wps=$(submit --dependency=afterok:$jid_real_comp "$COMPILE_DIR/wpscomp.scr") || exit 1
echo "Submitted wpscomp.scr as Job ID $jid_wps"

# The geography download only needs the WPS clone, so it runs alongside the rest
jid_geog=$(submit --dependency=afterok:$jid_clone "$COMPILE_DIR/geogdl.scr") || exit 1
echo "Submitted geogdl.scr as Job ID $jid_geog"

echo "Compilation successfully submitted. Use 'squeue -u $USER' to check job status."
echo "If a step fails, the jobs after it will stay pending with reason DependencyNeverSatisfied;"
echo "cancel them with 'scancel', fix the problem, and re-run this script."
