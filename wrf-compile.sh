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

WORK=/lustre/work/$USER
COMPILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compile"

# Clone a repository unless it already exists (so this script can be re-run after a failure)
clone() {
    local dest="$1"; shift
    if [ -d "$dest" ]; then
        echo "$dest already exists, skipping clone"
    else
        git clone "$@" "$dest" || exit 1
    fi
}

# Submit a job and print its ID, or exit if submission fails
submit() {
    local jid
    jid=$(sbatch --parsable --mail-user="$EMAIL" "$@") || { echo "Failed to submit: $*" >&2; exit 1; }
    echo "${jid%%;*}"
}

## Clone sources ##############################################################
cd "$WORK" || exit 1

# spack, checked out at its latest release
if [ -d "$WORK/spack" ]; then
    echo "$WORK/spack already exists, skipping clone and checkout"
else
    git clone https://github.com/spack/spack "$WORK/spack" || exit 1
    SPACK_RELEASE=$(git -C "$WORK/spack" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1) \
        || { echo "No spack release tag found in $WORK/spack" >&2; exit 1; }
    echo "Checking out spack $SPACK_RELEASE"
    git -C "$WORK/spack" checkout "$SPACK_RELEASE" || exit 1
fi

clone "$WORK/boxmg4wrf" --single-branch --branch main https://github.com/MicroTed/boxmg4wrf --recursive
clone "$WORK/wrf4-elec" --single-branch --branch release-v4.6.1-elec https://github.com/MicroTed/wrf4-elec --recursive
clone "$WORK/WPS" --single-branch --branch release-v4.6.0 https://github.com/wrf-model/WPS --recursive

# Enable electrification in quarter circle hodograph test
TEST_DIR="$WORK/wrf4-elec/test/em_quarter_ss"
for f in input_sounding namelist.input; do
    if [ ! -f "$TEST_DIR/electest/$f" ]; then
        echo "$TEST_DIR/electest/$f not found" >&2
        exit 1
    fi
    rm -f "$TEST_DIR/$f"
    cp "$TEST_DIR/electest/$f" "$TEST_DIR/$f"
done

cd - > /dev/null
echo "Submitting compile steps with dependencies..."

jid_spack=$(submit "$COMPILE_DIR/spack_ins.scr") || exit 1
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

# The geography download doesn't depend on anything, so it runs alongside the rest
jid_geog=$(submit "$COMPILE_DIR/geogdl.scr") || exit 1
echo "Submitted geogdl.scr as Job ID $jid_geog"

echo "Compilation successfully submitted. Use 'squeue -u $USER' to check job status."
echo "If a step fails, the jobs after it will stay pending with reason DependencyNeverSatisfied;"
echo "cancel them with 'scancel', fix the problem, and re-run this script."
