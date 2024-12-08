#!/usr/bin/env bash

#set -x
#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
	{ echo "cannot locate ${SCRIPTDIR}/spack_setup.sh"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-compilers"
spack_yaml="spack-${spack_env}.yaml"

# when we initialize this environment from scratch:
custom_env_yaml_initialization() {

    cat >${spack_yaml} <<EOF
spack:
  config:
    source_cache: ${spack_source_cache}
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_pkg_install_path}
      projections:
          all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
          ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
          gcc: '{name}/{version}'
          llvm: '{name}/{version}'
          nvhpc: '{name}/{version}'
          cuda: '{name}/{version}'
          intel-oneapi-compilers: '{name}/{version}'
          intel-oneapi-compilers-classic: '{name}/{version}'

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
        # what we want for defaults, when the newest version is not suitable
        # https://spack.readthedocs.io/en/latest/module_file_support.html#select-default-modules
        defaults:
          - ${spack_core_compiler}
          - intel-oneapi-compilers@2024.2.1
        all:
          autoload: direct
          environment:
            set:
              '{name}_ROOT': '{prefix}'

        intel-oneapi-compilers:
           environment:
             prepend_path:
               PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin'
               LD_LIBRARY_PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64'
             set:
               FORT_BUFFERED: 'TRUE'

        intel-oneapi-compilers-classic:
           environment:
             prepend_path:
               PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin'
               LD_LIBRARY_PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64'
             set:
               FORT_BUFFERED: 'TRUE'

        nvhpc:
           environment:
             prepend_path:
               PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin'
               LD_LIBRARY_PATH: '${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64'

        projections:
          all: '{name}/{version}'
          intel-oneapi-compilers: 'intel-oneapi/{version}'
          intel-oneapi-compilers-classic: 'intel-classic/{version}'

  packages:
    all:
      compiler:: [${spack_system_compiler}]
    gcc:
      require: [+piclibs, 'languages=c,c++,fortran,go']
    cuda:
      require: [+allow-unsupported-compilers]

  specs:
    - lmod
    - ${spack_core_compiler}
    - gcc@14
    - gcc@13
    - gcc@12
    - gcc@11
    - gcc@10
    - gcc@4
EOF
} # < -- end custom_env_yaml_initialization()

activate_env
#spack mark --all --implicit
spack compiler find && spack compilers
show_spack_configs
cat <<EOF
 -------------------------------------------------------------------------------
| ${spack_env} - phase 1 - installing
|    ${spack_core_compiler} and other gccs using ${spack_system_compiler}
 -------------------------------------------------------------------------------
EOF
spack concretize --fresh || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
build_spack_pkgs

# clean all that gcc cruft before moving on, to not fill our build stage
spack clean -s

spack load ${spack_core_compiler} && spack compiler add && spack unload --all && spack compiler list \
 	|| exit 1

# build llvm, download aocc, intel, and nvhpc compilers
cat <<EOF
 -------------------------------------------------------------------------------
| ${spack_env} - phase 2 - installing additional compilers
 -------------------------------------------------------------------------------
EOF
spack add \
      intel-oneapi-compilers@=2024.2.1 %${spack_core_compiler} \
      intel-oneapi-compilers@=2025.0.0 %${spack_core_compiler} \
      intel-oneapi-compilers-classic@=2021.10.0 %${spack_core_compiler} \
      nvhpc@24 %${spack_core_compiler} \
      cuda@12 %${spack_core_compiler}

#      llvm@19+flang %${spack_core_compiler} \

spack concretize --fresh || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
build_spack_pkgs

# build/refresh the lmod module tree
### ** delete the whole tree only at the first (compiler) level. **
### ** subsequent steps are additive **
my_spack_refresh_lmod --delete-tree -y

# create some manual modules for the system compiler:
mkdir -p "${spack_lmod_root}/gcc/${spack_system_gcc_version}"{,-m32}

cat <<EOF > "${spack_lmod_root}/Core/gcc/${spack_system_gcc_version}.lua"
whatis("Name : gcc")
whatis("Version : ${spack_system_gcc_version}")
whatis("Target : x86_64")
whatis("Short description : The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.")
whatis("(base OS version)")
help([[Name   : gcc]])
help([[Version: ${spack_system_gcc_version}]])
help([[Target : x86_64]])
help()
help([[This GNU Compiler Collection includes front ends for C, C++, and Fortran, as well as libraries for these languages.]])
family("compiler")
prepend_path("MODULEPATH","${spack_lmod_root}/gcc/${spack_system_gcc_version}")
setenv("CC","/usr/bin/gcc")
setenv("CXX","/usr/bin/g++")
setenv("FC","/usr/bin/gfortran")
setenv("F77","/usr/bin/gfortran")
setenv("GCC_ROOT","/usr")
EOF

cat <<EOF > "${spack_lmod_root}/Core/gcc/${spack_system_gcc_version}-m32.lua"
whatis("Name : gcc")
whatis("Version : ${spack_system_gcc_version} (32-bit executables)")
whatis("Target : x86_64")
whatis("Short description : The GNU Compiler Collection includes front ends for C, C++, Objective-C, Fortran, Ada, and Go, as well as libraries for these languages.")
whatis("(base OS version)")
help([[Name   : gcc]])
help([[Version: ${spack_system_gcc_version}]])
help([[Target : x86_64]])
help()
help([[This GNU Compiler Collection includes front ends for C, C++, and Fortran, as well as libraries for these languages (32-bit compilation).]])
family("compiler")
prepend_path("MODULEPATH","${spack_lmod_root}/gcc/${spack_system_gcc_version}-m32")
setenv("CC","/usr/bin/gcc -m32")
setenv("CXX","/usr/bin/g++ -m32")
setenv("FC","/usr/bin/gfortran -m32")
setenv("F77","/usr/bin/gfortran -m32")
setenv("GCC_ROOT","/usr")
EOF
