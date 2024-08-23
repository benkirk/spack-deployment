#!/usr/bin/env bash

# process command line arguments to get a specific system config, if desired
parse_args() {

    origArgs="${@}"

    usage() {

        cat <<EOF
usage: ${0} ...args...

where args are:
       <-h|--help>            : display this help message
       <-d|--delete-env>      : delete the environment, recreate & activate
       <-c|--concretize-only> : concretize only, do not install
       <-n|--dry-run>         : echo only, do not execute
       <--no-mirrror>         : do not update source mirror with source code packages
       <-rc|--system-config>  : alternate system configuration file (default: default.cfg)
EOF
    }


    export delete_env=false
    export dryrun=false
    export update_source_mirror=true
    export concretize_only=false
    export echo_cmd=""
    export spack_system_cfg="default.cfg"

    while [ ${#} -gt 0 ] ; do
        case ${1} in

            "-h"|"--help")
                usage
                exit 1
                ;;

            "-d"|"--delete-env")
                export delete_env=true
                ;;

            "-n"|"--dry-run")
                export dryrun=true
                export echo_cmd="echo"
                echo " --> DRY-RUN ONLY!"
                ;;

            "--no-mirror")
                export update_source_mirror=false
                echo " --> NOT UPDATING SOURCE MIRROR"
                ;;

            "-c"|"--concretize-only")
                echo " --> CONCRETIZE ONLY (no build)"
                export concretize_only=true
                ;;

            "-rc"|"--system-config")
                export spack_system_cfg=${2}
                shift
                ;;

            *)
                echo "unrecognized argument: ${1}"
                echo "  file or directory name expected!!"
                usage
                exit 1
        esac
        shift # past argument
    done
}

parse_args "${@}"



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
    target: [x86_64_2]
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
my_spack_refresh_lmod() {

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



# function to loop over outer prodcut of (compiler)x(spkgs)
comp_spkg_loop() {

    for comp in "${COMPS[@]}"; do
        for spkg in "${SPKGS[@]}"; do
            ${echo_cmd} spack add ${spkg} %${comp}
        done
    done
}



# function to loop over outer prodcut of (compiler)x(mpis)x(parallel packages)
comp_ppkg_loop() {

    # we will look for MPIs in ${parent_env}
    # which defaults to the same as ${spack_env} when not set
    parent_env="${parent_env:-"${spack_env}"}"

    for comp in "${COMPS[@]}"; do
        for mpi in "${MPIS[@]}"; do
            # make sure we have the requested MPI - otherwise abort.
            # (prevents us from accidientally installing MPIs we might not want)
            mpi_desc="$(spack env activate ${parent_env} && spack find --format="{name}@={version}%{compiler} {hash}" ${mpi}%${comp})" \
                || { echo "Cannot locate requested MPI: ${mpi}%${comp}"; exit 1; }

            mpi_spec="$(echo ${mpi_desc} | awk '{print $1}')"
            mpi_hash="$(echo ${mpi_desc} | awk '{print $2}')"

            echo "For ${mpi_desc}:"

            ${echo_cmd} spack mark --explicit "/${mpi_hash}"

            for ppkg in "${PPKGS[@]}"; do
                ${echo_cmd} spack add ${ppkg} %${comp} ^/${mpi_hash}
            done
        done
    done
}



# function to loop over outer prodcut of both
# (compiler)x(serial packages) & (compiler)x(mpis)x(parallel packages)
comp_spkg_ppkg_loop() {

    comp_spkg_loop
    comp_ppkg_loop
}



# shell function to take a list of previously installed packages and treat
# them as fixed externals
my_build_required_pkgs() {

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
my_spack_update_buildcache() {
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
show_spack_configs() {
    for arg in repos mirrors concretizer config modules view packages compilers; do
        spack config blame ${arg} && echo && echo # show our current configuration, with what comes from where
    done
}



custom_env_yaml_initialization() {
    # no-op, can be redefined later as needed
    return
}


# shell function to activate a spack environment
activate_env() {

    # delete existing env, if requested (spack will issue a message if existed, so no need to...)
    ${delete_env} && spack env remove -y ${spack_env} 2>/dev/null

    # activate (if exists) and exit
    spack env activate ${spack_env} 2>/dev/null \
        && echo "Activated existing environment ${spack_env}" \
        && return

    # if we get here, the requested environment never existed
    # or was just deleted.
    custom_env_yaml_initialization
    echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"
    spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
    spack env activate ${spack_env} || exit 1
}


# navigate to our clone directory and set up the spack environment
cd ${spack_clone_path} && pwd && . share/spack/setup-env.sh || exit 1

[ -d ${spack_source_cache}/_source-cache/ ] && spack mirror add mysrcmirror ${spack_source_cache}
[ -d ${spack_build_cache}                 ] && spack mirror add mybinmirror ${spack_build_cache}  && spack mirror list

mkdir -p ${spack_build_path} && cd ${spack_build_path} && echo "pwd=$(pwd)" || exit 1
echo "Finished initalization from ${SCRIPTDIR}/spack_setup.sh"
