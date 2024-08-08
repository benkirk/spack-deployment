#!/usr/bin/env bash

#----------------------------------------------------------------------------
# --- BEGIN typical common intialization
app_name="$( basename "${BASH_SOURCE[0]}" .sh)"

# common configuration for building apps
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/common.cfg ] && . ${SCRIPTDIR}/common.cfg "${@}" || \
    { echo "cannot locate ${SCRIPTDIR}/common.cfg}"; exit 1; }

parse_args "${@}"

# Activate the "${spack_deployment}-hpc-apps" spack environment, query its configuration,
# and prepare to add specs for this app
activate_spack_env || exit 1
# --- END typical common intialization
#----------------------------------------------------------------------------



#----------------------------------------------------------------------------
# --- BEGIN app-specific stuff

# SPKGS is a bash array of serial packages to be built (unset if none).
# PPKGS is a bash array of parallel (mpi-based) packages to be built (unset if none).
# COMPS is a bash array of compilers to use.
unset SPKGS

# Dakota & gcc@13 dont mix
COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0')
PPKGS=("dakota@6.18+mpi ^${BOOST183}")
comp_spkg_ppkg_loop

# --- END app-specific stuff
#----------------------------------------------------------------------------




#----------------------------------------------------------------------------
# --- BEGIN typical common build & finalization
${echo_cmd} spack concretize --fresh || exit 1

# populate our source cache mirror with any new packages introduced by these specs
${echo_cmd} spack mirror create --directory ${spack_source_cache} --all

${dryrun} || build_spack_apps

# build/refresh the lmod module tree
# (note that any app-specific module or projection customization in spack.yaml
# must go in step-03 of the build bootstrap process, unfortunately.)
${dryrun} || my_spack_refresh_lmod -y
# --- END typical common build & finalization
#----------------------------------------------------------------------------
