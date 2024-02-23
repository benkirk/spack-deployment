#!/usr/bin/env bash

#set -x
#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && . ${SCRIPTDIR}/spack_setup.sh || \
	{ echo "cannot locate ${SCRIPTDIR}/spack_setup.sh"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-compilers"
spack_yaml="spack-${spack_env}.yaml"

echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

cat >${spack_yaml} <<EOF
spack:
  config:
    source_cache: ${spack_source_cache}
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_clone_path}/${spack_env}
      projections:
          all: '{name}/{version}-{hash:7}'

  concretizer:
    unify: false

  view:
    compilers:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}'
      link: roots
      link_type: symlink

  modules:
    default:
      enable::
        - lmod
      arch_folder: false
      roots:
        lmod: ${spack_lmod_root}
      lmod:
        exclude_implicits: true
        hash_length: 0
        exclude:
          - binutils
          - lmod
        core_compilers:
          - ${spack_system_compiler}
        core_specs:
          - aocc
          - gcc
          - intel-oneapi-compilers
          - intel-parallel-studio
          - llvm
          - nvhpc
          - cuda
        all:
          environment:
            set:
              '{name}_ROOT': '{prefix}'
        aocc:
           environment:
             set:
               CXXFLAGS: '-std=gnu++17 --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               CFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               FCFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               FFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               LDFLAGS: '-Wl,-rpath,${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/lib -Wl,-rpath,${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64'
        intel-oneapi-compilers:
           environment:
             set:
               CXXFLAGS: '-std=gnu++17 --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               CFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               FCFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               FFLAGS: '--gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0'
               LDFLAGS: '-L${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64 -Wl,-rpath,${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64'

        projections:
          all: '{name}/{version}'
          intel-oneapi-compilers: 'oneapi/{version}'

  packages:
    all:
      compiler:: [${spack_system_compiler}]
    gcc:
      variants: [+piclibs, 'languages=c,c++,fortran,go']
    cuda:
      variants: [+allow-unsupported-compilers]

  specs:
    - lmod ^lua@5.3  # why 5.3?  Because 5.4 fails to build on a minimal Rocky8 host
    - gcc@12
    - gcc@11.3.0
    #- gcc@10
    #- gcc@9
    - gcc@4
EOF

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
#spack external find --not-buildable openssl ncurses #perl
spack compiler find && spack compilers
for arg in repos mirrors concretizer packages config modules compilers; do
    spack config blame ${arg} && echo && echo # show our current configuration, with what comes from where
done

spack concretize --fresh \
    || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
for bg_inst in $(seq 1 ${n_concurrent_installs}); do
    spack install ${spack_install_flags} || [ "x${spack_install_flags}" != "x${spack_install_flags_no_cache}" ] && spack install ${spack_install_flags_no_cache} &
done
# run a single install in the foreground.  try with our build flags, which could use a binary cache,
# but fall back to a --no-cache attempt if necessary
spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
wait

# clean all that gcc cruft before moving on, to not fill our build stage
spack clean -s

spack load ${spack_core_compiler} && spack compiler add && spack unload --all && spack compiler list \
 	|| exit 1

# build llvm, download aocc, intel, and nvhpc compilers
spack add \
   intel-oneapi-compilers@2023.1.0 %${spack_core_compiler} \
   nvhpc@22.9 %${spack_core_compiler} \
   cuda@11.8 %${spack_core_compiler} \
   && spack concretize --fresh \
   || exit 1

#    nvhpc@23.3 %${spack_core_compiler} \

#   llvm@16.0.2+flang %${spack_core_compiler} \
#   llvm@16.0.2+flang+cuda cuda_arch=80 %${spack_core_compiler} \
#   cuda %${spack_core_compiler} \

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
for bg_inst in $(seq 1 ${n_concurrent_installs}); do
    spack install ${spack_install_flags} || [ "x${spack_install_flags}" != "x${spack_install_flags_no_cache}" ] && spack install ${spack_install_flags_no_cache} &
done
# run a single install in the foreground.  try with our build flags, which could use a binary cache,
# but fall back to a --no-cache attempt if necessary
spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
wait

# build/refresh the lmod module tree
### ** delete the whole tree only at the first (compiler) level. **
### ** subsequent steps are additive **
my_spack_refresh_lmod --delete-tree -y
