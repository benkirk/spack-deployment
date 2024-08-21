#!/usr/bin/env bash

# process command line arguments to get a specific system config, if desired
spack_system_cfg="default.cfg"

while [[ $# -gt 0 ]]; do
    case $1 in
        -rc|--system-config)
            spack_system_cfg=$2
            shift
            ;;

        *)
            ;;
    esac
    shift
done

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/conf/${spack_system_cfg} ] && source ${SCRIPTDIR}/conf/${spack_system_cfg} || \
	{ echo "cannot locate ${SCRIPTDIR}/conf/${spack_system_cfg}"; exit 1; }
#----------------------------------------------------------------------------

mkdir -p ~/.spack/
rm -f ~/.spack/*.yaml

cat > ~/.spack/packages.yaml <<EOF
packages:
  all:
    target: [x86_64]
EOF

cat > ~/.spack/concretizer.yaml <<EOF
concretizer:
  targets:
    granularity: generic
EOF

cat > ~/.spack/config.yaml <<EOF
# The default url fetch method to use.
# If set to 'curl', Spack will require curl on the user's system
# If set to 'urllib', Spack will use python built-in libs to fetch
config:
  db_lock_timeout: 10
  url_fetch_method: curl
  #install_tree:
  #  padded_length: 128

EOF

# install spack repo: this step could be pinned to a fixed version of spack, if desired
[ ! -d ${spack_clone_path} ] \
    && ${spack_clone_command} ${spack_clone_path}

# spack supports Lmod, but having Lmod in our shell environment *before* invoking spack is a recipe for trouble.
# below is an attempt to 'sanitize' our shell from the broader FSL Lmod
type module >/dev/null 2>&1 \
    && module --force purge && module list \
    && module unuse ${MODULEPATH} \
    && unset MODULEPATH MODULEPATH_ROOT MODULESHOME __LMOD_REF_COUNT_MODULEPATH LMOD_MODULERCFILE LMOD_SYSTEM_DEFAULT_MODULES module \
    && env | grep MODU | sort

# shell function to clean/refresh module tree,
# passing along any additional arguments
my_spack_refresh_lmod()
{
    echo "Refreshing lmod modules at ${spack_lmod_root}"

    spack module lmod refresh $@ \
        && . $(spack location -i lmod)/lmod/lmod/init/bash \
        && . ${spack_clone_path}/share/spack/setup-env.sh \
        && module unuse ${MODULEPATH} \
        && module use ${spack_lmod_root}/Core \
        && module avail

cat > ~/spack_modules_${spack_deployment}.sh <<EOF
# To use this module stack do the following:

# remove any existing module implementation fron the current shell, as much as possible
type module >/dev/null 2>&1 \\
    && module --force purge \\
    && module unuse \${MODULEPATH} \\
    && unset MODULEPATH MODULEPATH_ROOT MODULESHOME __LMOD_REF_COUNT_MODULEPATH LMOD_MODULERCFILE LMOD_SYSTEM_DEFAULT_MODULES module \
    && env | grep MODU | sort

# use the spack-provided lmod & module tree.  spack defaults to TCL modules, so swap for Lmod.
. $(spack location -i lmod)/lmod/lmod/init/bash \\
    && . ${spack_clone_path}/share/spack/setup-env.sh \\
    && module unuse \${MODULEPATH} \\
    && module use ${spack_lmod_root}/Core \\
    && module avail
EOF
cat ~/spack_modules_${spack_deployment}.sh
}


# shell fucntion to build spack packages, after
# they have been added & concretized in an active environment
build_spack_pkgs() {

    # run a number of installs in the background
    for bg_inst in $(seq 1 ${n_concurrent_installs}); do
        # install (possibly from cache), if fails potentially try again ignoring cache
        spack install ${spack_install_flags} \
            || [ "x${spack_install_flags}" != "x${spack_install_flags_no_cache}" ] && spack install ${spack_install_flags_no_cache} &
    done

    # run a single install in the foreground.  try with our build flags, which could use a binary cache,
    # but fall back to a --no-cache attempt if necessary
    spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
    wait
}



# shell function to take a list of previously installed packages and treat
# them as fixed externals
my_build_required_pkgs()
{
    [ $# -ge 2 ] || { echo "usage: to my_build_required_pkgs <SPACK_SEARCH_ENVIRONMENT> pkg1 pkg2 ..."; exit 1; }
    local spack_search_env=$1 && shift
    spack env activate ${spack_search_env} || { echo "spacktivate ${spack_search_env} failed!!" ; exit 1; }

    echo "Locating fixed externals from environment ${spack_search_env}..."
    echo "# packages pinned to existing versions follow..." > fixed_packages.yaml

    for requested_pkg in $(echo ${@} | tr " " "\n" | sort | uniq); do

        cat >> fixed_packages.yaml <<EOF
    ${requested_pkg}:
      buildable: False
      externals:
EOF
        while read pkg_hash; do

            #echo ${pkg_hash}
            pkg_spec="$(spack find --format "{name}@={version}" "/${pkg_hash}")"
            pkg_path="$(spack location --install-dir "/${pkg_hash}")"

            echo "  --> ${pkg_spec} ${pkg_path}"

            cat >> fixed_packages.yaml <<EOF
      - spec: ${pkg_spec}
        prefix: ${pkg_path}
EOF
        done < <(spack find --format {hash} ${requested_pkg})
    done
}



# shell function to update our buildcache with any new packages
# dispatched a number of simultaneous buildcache steps in parallel to speed thing up
# and finishes with an update to the index
my_spack_update_buildcache()
{
    mkdir -p ${spack_build_cache}

    set +m # turn off job control to prevent flood of "Done..." messages from background processes

    # create
    n_concurrent=8
    while read pkg_hash; do

        desc=$(spack find -Lv --show-full-compiler "/${pkg_hash}" | grep "${pkg_hash}")

        # 'parallelize' this process by launching up to n_concurrent buildcache jobs in the background
        echo -n "${desc}, build cache jobid/pid=" ; \
            spack buildcache create \
                  --only=package --unsigned ${spack_build_cache} "/${pkg_hash}" >/dev/null &

        # see how many jobs we have launched, block & wait when equal to n_concurrent
        while true; do
            n_current=$(jobs -p | wc -l) && [ ${n_current} -lt ${n_concurrent} ] && break || sleep 0.2s
        done
    done < <(spack find --format {hash})

    echo "waiting for all buildcache create steps to complete..."
    wait

    set -m

    # index the updated buildcache
    echo "updating buildcache index..."
    spack buildcache update-index ${spack_build_cache}
}



# shell function to list spack configs, intended to be used inside an activated environment
show_spack_configs()
{
    for arg in repos mirrors concretizer config modules packages compilers; do
        spack config blame ${arg} && echo && echo # show our current configuration, with what comes from where
    done
}



# navigate to our clone directory and set up the spack environment
cd ${spack_clone_path} && pwd && . share/spack/setup-env.sh || exit 1

[ -d ${spack_source_cache}/_source-cache/ ] && spack mirror add mysrcmirror ${spack_source_cache}
[ -d ${spack_build_cache}                 ] && spack mirror add mybinmirror ${spack_build_cache}  && spack mirror list

mkdir -p ${spack_build_path} && cd ${spack_build_path} && echo "pwd=$(pwd)" || exit 1
echo "Finished initalization from ${SCRIPTDIR}/spack_setup.sh"
