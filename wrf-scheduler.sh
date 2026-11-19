#!/bin/bash
# automated WRF/wrf-elec submission script for Texas Tech HPCC.
# Created 10 April 2025 by Sam Gardner <samuel.gardner@ttu.edu>

# Find my own directory and export it so that the other scripts can use it
AUTOQUEUE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AUTOQUEUE_DIR

echo "Submitting WRF steps with dependencies..."

# Submit datafetch
jid1=$(sbatch "$AUTOQUEUE_DIR"/datafetch.scr | awk '{print $4}')
echo "Submitted datafetch.scr as Job ID $jid1"

# Submit ungrib after datafetch
jid2=$(sbatch --dependency=afterok:$jid1 "$AUTOQUEUE_DIR"/ungrib.scr | awk '{print $4}')
echo "Submitted ungrib.scr as Job ID $jid2"

# Submit metgrid after ungrib
jid3=$(sbatch --dependency=afterok:$jid2 "$AUTOQUEUE_DIR"/metgrid.scr | awk '{print $4}')
echo "Submitted metgrid.scr as Job ID $jid3"

# Submit real after metgrid
jid4=$(sbatch --dependency=afterok:$jid3 "$AUTOQUEUE_DIR"/real.scr | awk '{print $4}')
echo "Submitted real.scr as Job ID $jid4"

# Submit wrf integration after real
jid5=$(sbatch --dependency=afterok:$jid4 "$AUTOQUEUE_DIR"/wrf-integ.scr | awk '{print $4}')
echo "Submitted wrf-integ.scr as Job ID $jid5"

echo "WRF run successfully submitted. Use 'squeue -u $USER' to check job status."
