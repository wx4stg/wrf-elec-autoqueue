wrf-elec-autoqueue
---

Scripts I'm using to automatically queue up and run wrf-elec on TTU HPCC. Run wrf-scheduler.sh to execute

Requires:

- spack installed in /lustre/work/$USER/spack with the following packages installed:
    `gcc glibc openmpi parallel-netcdf wps netcdf-fortran wrf automake hdf5 bzip2 netcdf-c jasper libpng zlib-ng zlib`
- compiled build of wrf-elec in /lustre/work/$USER/wrf4-elec
- compiled build of WPS in /lustre/work/$USER/WPS
- run `git clone https://github.com/wx4stg/wrf-elec-autoqueue /lustre/work/$USER/SUB` to get these scripts
- micromamba environment 'autowrf' with `requests` installed

Following my [installation instructions](https://gist.github.com/wx4stg/8b53875068521155c74c0ac4fe5ca87d) to the letter should give you a compatible install.