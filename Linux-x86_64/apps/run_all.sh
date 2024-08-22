#!/usr/bin/env bash

#----------------------------------------------------------------------------
# common configuration for building apps
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#----------------------------------------------------------------------------

cd ${SCRIPTDIR} || exit 1

for app in *.sh; do
    [[ "${app}" == "$(basename ${0})" ]] && continue

    echo "Running ${app} ${@}"
    #echo ./${app} "${@}"
done
