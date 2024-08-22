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

# Dakota needs an older version of boost, not properly reflected in its package.py file.
# we could update the package.py, but that's one more thing to maintain. So do it here
# instead.

${echo_cmd} spack config remove 'packages:dakota'
${echo_cmd} spack config add 'packages:dakota:require:["^boost@1.83.0"]'
# (could show again for debugging): show_spack_configs

# SPKGS is a bash array of serial packages to be built (unset if none).
# PPKGS is a bash array of parallel (mpi-based) packages to be built (unset if none).
# COMPS is a bash array of compilers to use.
# Dakota & gcc@13 dont mix

COMPS=('gcc@=11.4.0' 'gcc@=12.3.0')
SPKGS=('boost@=1.83.0')
comp_spkgs_loop


PPKGS=('dakota@=6.18')
# override, dakota seems especially bad about interfering with itself
# when compiling multiple versions simultaneously
n_concurrent_installs=0
comp_ppkg_loop

# --- END app-specific stuff
#----------------------------------------------------------------------------




#----------------------------------------------------------------------------
# --- BEGIN typical common build & finalization
${dryrun} || build_spack_apps
# --- END typical common build & finalization
#----------------------------------------------------------------------------
