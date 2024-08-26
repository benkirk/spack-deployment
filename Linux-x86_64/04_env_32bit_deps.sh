#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-baseos-32bit-deps"
spack_yaml="spack-${spack_env}.yaml"

# when we initialize this environment from scratch:
custom_env_yaml_initialization() {

    cat >${spack_yaml} <<EOF
spack:

  config:
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_pkg_install_path}
      projections:
          all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'

  concretizer:
    unify: false

  modules:
    view_relative_modules:
      use_view: my_view
    prefix_inspections:
      lib:
        - LD_LIBRARY_PATH
      lib64:
        - LD_LIBRARY_PATH
    default::
      enable::
        - lmod
      arch_folder: false
      roots:
        lmod: ${spack_lmod_root}
      lmod:
        hierarchy:
          - mpi
        exclude_implicits: true
        hash_length: 0
        exclude:
          - lmod
        core_compilers:
          - None
        all:
          autoload: direct
          environment:
            set:
              '{name}_ROOT': '{prefix}'

  view:
    my_view:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
      link: roots
      link_type: symlink

  compilers:
  - compiler:
      spec: ${spack_system_compiler}-m32
      paths:
        cc: /usr/bin/gcc
        cxx: /usr/bin/g++
        f77: /usr/bin/gfortran
        fc: /usr/bin/gfortran
      flags:
        cflags: -m32
        cxxflags: -m32
        fflags: -m32
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  packages:
    all:
      compiler:: [${spack_system_compiler}-m32]
      variants: [~mpi, +fortran] # make sure mpi doesn't sneak in through hdf5 (to paraview), or any sub-package.  enable fortran where applicable.

    mpi:
      buildable: False # No MPIs at all in step-04
    boost:
      require: [+atomic, +chrono, +date_time, +filesystem, +graph, +json, +log, +math, +multithreaded, +program_options, +random, +regex, +serialization, +shared, +signals, +stacktrace, +system, +timer, cxxstd=11]
    hdf5:
      require: [~fortran, +cxx, +szip, +hl] # <-- 32-bit fortran error: Fortran compiler requires either intrinsic functions SIZEOF or STORAGE_SIZE
EOF

    # packages we don't want to rebuild -
    # so instead we take them as fixed from a previous environment
    my_build_required_pkgs \
        "${spack_deployment}-base" \
        bc cmake gmake curl diffutils lmod perl tar \
        && echo "Fixed Externals:" && cat fixed_packages.yaml | tee -a ${spack_yaml}

    cat >>${spack_yaml} <<EOF
  specs:
    - boost
    - hdf5
    - zlib
    - zlib-ng
    - bzip2
    - unzip
    - xz
EOF
}  # < -- end custom_env_yaml_initialization()

activate_env
#spack mark --all --implicit
show_spack_configs
spack compilers

spack concretize --fresh \
    || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
build_spack_pkgs

# build/refresh the lmod module tree
my_spack_refresh_lmod -y
