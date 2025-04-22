#!/bin/bash
# Cleanup WRF data after running
# Created 21 April 2025 by Sam Gardner <samuel.gardner@ttu.edu>

rm /lustre/work/$USER/WPS/data/*
rm /lustre/work/$USER/WPS/geogrid.log.*
rm /lustre/work/$USER/WPS/met_em.d*
rm /lustre/work/$USER/WPS/FILE*
rm /lustre/work/$USER/WPS/GRIBFILE.*

rm /lustre/work/$USER/wrf4-elec/run/rsl.error*
rm /lustre/work/$USER/wrf4-elec/run/rsl.out*
rm /lustre/work/$USER/wrf4-elec/run/met_em.d*
rm /lustre/work/$USER/wrf4-elec/run/wrfbdy_d*
rm /lustre/work/$USER/wrf4-elec/run/wrfinput_d*

if [[ "$*" == *"outputdata"* ]]
then
    rm /lustre/work/$USER/wrf4-elec/run/wrfout_d*
fi

if [[ "$*" == *"geodata"* ]]
then
    rm /lustre/work/$USER/WPS/geo_em.d*
fi
