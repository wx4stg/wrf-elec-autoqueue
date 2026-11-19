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

---
Running wrf on multiple nodes:

What to check prior to submitting a multinode job:

- That prrte is installed in spack (comes automatically w/ open mpi 5 but check): spack find prrte
- wrf was compiled for mpi (dmpar)
- the run folder is on shared storage
- confirm open mpi was built with slurm: ompi_info | grep -i slurm
  
Notes:
- Updated 'wrf-integ.scr' from running only a single node (128 ranks) to multinodes. For larger or finer domains you may need more than one node.
- A common error: 'prted: command not found'
- On a single node, everything runs on one machine. On several nodes, 'mpirun' has to start a helper daemon, 'prted', on each of the other nodes and that daemon then starts the wrf ranks there.
- open mpi 5 does not by default include 'prted', but instead it is located in a separate PRRTE package.spack installs prrte as its own package with its own prefix, and 'spack load openmpi' does not put prrte's 'bin/' and 'lib/' on your paths. The fix to this is present in the updated 'wrf-integ.scr'.
- Additionally note 'wrf-integ.scr' is set to --nodes=1 as default, by make sure to specify the number of nodes prior to running the script.
