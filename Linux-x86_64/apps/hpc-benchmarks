#!/usr/bin/env bash

#----------------------------------------------------------------------------
# --- BEGIN typical common intialization
app_name="$( basename "${BASH_SOURCE[0]}" .sh)"

# common configuration for building apps
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/common.cfg ] && source ${SCRIPTDIR}/common.cfg "${@}" || \
    { echo "cannot locate ${SCRIPTDIR}/common.cfg}"; exit 1; }

# Activate the "${spack_deployment}-${app_name}" spack environment, query its configuration,
# and prepare to add specs for this app
create_and_activate_spack_env || exit 1
# --- END typical common intialization
#----------------------------------------------------------------------------



#----------------------------------------------------------------------------
# --- BEGIN app-specific stuff

# SPKGS is a bash array of serial packages to be built (unset if none).
# PPKGS is a bash array of parallel (mpi-based) packages to be built (unset if none).
# COMPS is a bash array of compilers to use.
unset SPKGS
PPKGS=('hpl' 'osu-micro-benchmarks')
comp_spkg_ppkg_loop

COMPS=("${GCCS[@]}")
PPKGS=('hpcg')
comp_spkg_ppkg_loop


# --- END app-specific stuff
#----------------------------------------------------------------------------



#----------------------------------------------------------------------------
# --- BEGIN typical common build & finalization
${dryrun} || build_spack_apps
# --- END typical common build & finalization
#----------------------------------------------------------------------------
