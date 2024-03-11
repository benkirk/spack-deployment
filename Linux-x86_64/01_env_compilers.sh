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
          - intel-oneapi-compilers-classic
          - llvm
          - nvhpc
          - cuda
        all:
          environment:
            set:
              '{name}_ROOT': '{prefix}'

        intel-oneapi-compilers:
           environment:
             prepend_path:
               PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin'
               LD_LIBRARY_PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64'

        intel-oneapi-compilers-classic:
           environment:
             prepend_path:
               PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin'
               LD_LIBRARY_PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64'

        nvhpc:
           environment:
             prepend_path:
               PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin'
               LD_LIBRARY_PATH: '${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64'

        projections:
          all: '{name}/{version}'
          intel-oneapi-compilers: 'intel-oneapi/{version}'
          intel-oneapi-compilers-classic: 'intel-classic/{version}'

  packages:
    all:
      compiler:: [${spack_system_compiler}]
    gcc:
      variants: [+piclibs, 'languages=c,c++,fortran,go']
    cuda:
      variants: [+allow-unsupported-compilers]

  specs:
    - lmod
    - gcc@12.3.0
    - gcc@11
    - gcc@10
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
      intel-oneapi-compilers@2023.2.1 %${spack_core_compiler} \
      intel-oneapi-compilers-classic@2021.10.0 %${spack_core_compiler} \
      nvhpc@23 %${spack_core_compiler} \
      cuda@11 %${spack_core_compiler} \
    && spack concretize --fresh \
    || exit 1

#       llvm@17+flang %${spack_core_compiler} \


#   nvhpc@22.9 %${spack_core_compiler} \
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

# create some manual modules for the system compiler:
sys_gcc_vers=$(echo "${spack_system_compiler}" | cut -d '@' -f2-)

mkdir -p "${spack_lmod_root}/gcc/${sys_gcc_vers}"{,-m32}

cat <<EOF > "${spack_lmod_root}/Core/gcc/${sys_gcc_vers}.lua"
whatis("Name : gcc")
whatis("Version : ${sys_gcc_vers}")
whatis("Target : x86_64")
whatis("Short description : The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.")
whatis("(base OS version)")
help([[Name   : gcc]])
help([[Version: ${sys_gcc_vers}]])
help([[Target : x86_64]])
help()
help([[The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.]])
family("compiler")
prepend_path("MODULEPATH","${spack_lmod_root}/gcc/${sys_gcc_vers}")
setenv("CC",/usr/bin/gcc")
setenv("CXX","/usr/bin/g++")
setenv("FC","/usr/bin/gfortran")
setenv("F77","/usr/bin/gfortran")
setenv("GCC_ROOT","/usr")
EOF

cat <<EOF > "${spack_lmod_root}/Core/gcc/${sys_gcc_vers}-m32.lua"
whatis("Name : gcc")
whatis("Version : ${sys_gcc_vers} (32-bit executables)")
whatis("Target : x86_64")
whatis("Short description : The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.")
whatis("(base OS version)")
help([[Name   : gcc]])
help([[Version: ${sys_gcc_vers}]])
help([[Target : x86_64]])
help()
help([[The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.]])
family("compiler")
prepend_path("MODULEPATH","${spack_lmod_root}/gcc/${sys_gcc_vers}-m32")
setenv("CC",/usr/bin/gcc -m32")
setenv("CXX","/usr/bin/g++ -m32")
setenv("FC","/usr/bin/gfortran -m32")
setenv("F77","/usr/bin/gfortran -m32")
setenv("GCC_ROOT","/usr")
EOF
