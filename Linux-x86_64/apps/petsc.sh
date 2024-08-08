#!/usr/bin/env bash

app_name="$( basename "${BASH_SOURCE[0]}" .sh)"

#----------------------------------------------------------------------------
# common configuration for building apps
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/common.cfg ] && . ${SCRIPTDIR}/common.cfg || \
    { echo "cannot locate ${SCRIPTDIR}/common.cfg}"; exit 1; }
#----------------------------------------------------------------------------

activate_spack_env || exit 1

#spack concretize --fresh || exit 1


unset SPKGS
COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0' 'gcc@13.2.0' 'oneapi@2023.2.4')
PPKGS=('petsc@3.17+hypre~hdf5~metis+mpi+openmp+scalapack+shared~suite-sparse~superlu-dist ^intel-oneapi-mkl')
comp_spkg_ppkg_loop

COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0' 'gcc@13.2.0')
PPKGS=('petsc@3.16+hypre~hdf5~metis+mpi+openmp+shared~suite-sparse~superlu-dist ^intel-oneapi-mkl')
comp_spkg_ppkg_loop
comp_spkg_ppkg_loop

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

spack concretize --fresh || exit 1

build_spack_pkgs

# build/refresh the lmod module tree
my_spack_refresh_lmod -y
