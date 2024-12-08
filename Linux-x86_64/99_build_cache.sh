#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------



#----------------------------------------------------------------------------
my_spack_update_buildcache_all_env
#----------------------------------------------------------------------------
