#!/bin/bash

echo "Submitting WRF steps with dependencies..."

# Submit datafetch
jid1=$(sbatch /lustre/work/$USER/SUB/datafetch.scr | awk '{print $4}')
echo "Submitted datafetch.scr as Job ID $jid1"

# Submit ungrib after datafetch
jid2=$(sbatch --dependency=afterok:$jid1 /lustre/work/$USER/SUB/ungrib.scr | awk '{print $4}')
echo "Submitted ungrib.scr as Job ID $jid2"

# Submit metgrid after ungrib
jid3=$(sbatch --dependency=afterok:$jid2 /lustre/work/$USER/SUB/metgrid.scr | awk '{print $4}')
echo "Submitted metgrid.scr as Job ID $jid3"

# Submit real after metgrid
jid4=$(sbatch --dependency=afterok:$jid3 /lustre/work/$USER/SUB/real.scr | awk '{print $4}')
echo "Submitted real.scr as Job ID $jid4"

# Submit wrf integration after real
jid5=$(sbatch --dependency=afterok:$jid4 /lustre/work/$USER/SUB/wrf-integ.scr | awk '{print $4}')
echo "Submitted wrf-integ.scr as Job ID $jid5"

echo "WRF run successfully submitted. Use 'squeue -u $USER' to check job status."
