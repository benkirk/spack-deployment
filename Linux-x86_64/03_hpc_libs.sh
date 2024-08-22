#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-hpc-libs"
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
          all: 'hpc-libs/{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
          ^mpi: 'hpc-libs/{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'

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
          - '%${spack_system_compiler}'
          - lmod
        core_compilers:
          - None
        all:
          autoload: direct
          environment:
            set:
              '{name}_ROOT': '{prefix}'
        projections:
          hdf5+mpi: '{name}-mpi/{version}'
          netcdf+mpi: '{name}-mpi/{version}'

  view:
    my_view:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
        ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
      link: roots
      link_type: symlink

  compilers:
  - compiler:
      spec: gcc@=13.2.0
      paths:
        cc: ${spack_pkg_install_path}/gcc/13.2.0/bin/gcc
        cxx: ${spack_pkg_install_path}/gcc/13.2.0/bin/g++
        f77: ${spack_pkg_install_path}/gcc/13.2.0/bin/gfortran
        fc: ${spack_pkg_install_path}/gcc/13.2.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: gcc@=12.3.0
      paths:
        cc: ${spack_pkg_install_path}/gcc/12.3.0/bin/gcc
        cxx: ${spack_pkg_install_path}/gcc/12.3.0/bin/g++
        f77: ${spack_pkg_install_path}/gcc/12.3.0/bin/gfortran
        fc: ${spack_pkg_install_path}/gcc/12.3.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: gcc@=11.4.0
      paths:
        cc: ${spack_pkg_install_path}/gcc/11.4.0/bin/gcc
        cxx: ${spack_pkg_install_path}/gcc/11.4.0/bin/g++
        f77: ${spack_pkg_install_path}/gcc/11.4.0/bin/gfortran
        fc: ${spack_pkg_install_path}/gcc/11.4.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: gcc@=10.5.0
      paths:
        cc: ${spack_pkg_install_path}/gcc/10.5.0/bin/gcc
        cxx: ${spack_pkg_install_path}/gcc/10.5.0/bin/g++
        f77: ${spack_pkg_install_path}/gcc/10.5.0/bin/gfortran
        fc: ${spack_pkg_install_path}/gcc/10.5.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: ${spack_system_compiler}
      paths:
        cc: /usr/bin/gcc
        cxx: /usr/bin/g++
        f77: /usr/bin/gfortran
        fc: /usr/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: nvhpc@=24.3
      paths:
        cc: ${spack_pkg_install_path}/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvc
        cxx: ${spack_pkg_install_path}/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvc++
        f77: ${spack_pkg_install_path}/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvfortran
        fc: ${spack_pkg_install_path}/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin
      extra_rpaths:
        - ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64

  - compiler:
      spec: oneapi@=2023.2.4
      paths:
        cc: ${spack_pkg_install_path}/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/icx
        cxx: ${spack_pkg_install_path}/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/icpx
        f77: ${spack_pkg_install_path}/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/ifx
        fc: ${spack_pkg_install_path}/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/ifx
      flags:
        cflags: -lpthread
        cxxflags: -lpthread
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_pkg_install_path}-base/gmake/4.3/bin
      extra_rpaths:
        - ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64

  - compiler:
      spec: intel@=2021.10.0
      paths:
        cc: ${spack_pkg_install_path}/intel-oneapi-compilers-classic/2021.10.0/bin/icc
        cxx: ${spack_pkg_install_path}/intel-oneapi-compilers-classic/2021.10.0/bin/icpc
        f77: ${spack_pkg_install_path}/intel-oneapi-compilers-classic/2021.10.0/bin/ifort
        fc: ${spack_pkg_install_path}/intel-oneapi-compilers-classic/2021.10.0/bin/ifort
      flags:
        cflags: -lpthread
        cxxflags: -lpthread
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin
      extra_rpaths:
        - ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64

#  - compiler:
#      spec: clang@=15.0.4
#      paths:
#        cc: ${spack_pkg_install_path}/llvm/15.0.4/bin/clang
#        cxx: ${spack_pkg_install_path}/llvm/15.0.4/bin/clang++
#        f77: ${spack_pkg_install_path}/llvm/15.0.4/bin/flang-new
#        fc: ${spack_pkg_install_path}/llvm/15.0.4/bin/flang-new
#      flags: {}
#      operating_system: ${os_version}
#      target: x86_64
#      modules: []
#      environment:
#        prepend_path:
#          PATH: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin
#      extra_rpaths:
#        - ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/lib64

  packages:
    all:
      compiler:: [ ${spack_core_compiler}, gcc, oneapi, intel ]
      providers:
        blas::      [intel-oneapi-mkl]
        lapack::    [intel-oneapi-mkl]
        scalapack:: [intel-oneapi-mkl]
        tbb::       [intel-oneapi-tbb]
        mpi::       [openmpi, mpich, intel-oneapi-mpi, mpt]

    boost:
      require: [+atomic, +chrono, +date_time, +filesystem, +graph, +json, +log, +math, +multithreaded, +program_options, +random, +regex, +serialization, +shared, +signals, +stacktrace, +system, +timer, cxxstd=11]
    hdf5:
      require: [+fortran, +cxx, +szip, +hl]
    intel-oneapi-mpi:
      require: [+generic-names]
    mpich:
      require: [+slurm]
    openmpi:
      require: [+legacylaunchers, schedulers=slurm]
EOF


    # packages we don't want to rebuild -
    # so instead we take them as fixed from a previous environment
    my_build_required_pkgs \
        "${spack_deployment}-base" \
        cmake autoconf libtool automake openssh perl findutils diffutils m4 curl tar pkgconf util-macros libszip \
        gmake gettext numactl libxml2 zlib zlib-ng zstd xz ncurses tcl readline bzip2 gdbm util-linux-uuid sqlite intel-oneapi-mkl \
        openssl libevent texinfo autoconf-archive libtirpc tcsh \
        libfabric ucx python \
        slurm \
        && echo "Fixed Externals:" && cat fixed_packages.yaml | tee -a ${spack_yaml}

    cat >>${spack_yaml} <<EOF
  specs:
    - lmod%${spack_core_compiler}
EOF
}  # < -- end custom_env_yaml_initialization()



# function to loop over outer prodcut of (compiler)x(mpis)
comp_mpis_loop() {

    for comp in "${COMPS[@]}"; do
        for mpi in "${MPIS[@]}"; do
            spack add ${mpi}% ${comp}
        done
    done
}



# build/refresh the lmod module tree.
# Occasionaly (v.0.22.1?) the MPIs somehow erroneoulsy
# became implicit along the way, and no module files were generated.
mark_mpis_explicit()
{
    for comp in "${COMPS[@]}"; do
        for mpi in "${MPIS[@]}"; do

            # make sure we have the requested MPI - otherwise abort.
            # (prevents us from accidientally installing MPIs we might not want)
            mpi_desc="$(spack find --format="{name}@={version}%{compiler} {hash}" ${mpi}%${comp})" \
                || { echo "Cannot locate requested MPI: ${mpi}%${comp}"; exit 1; }

            mpi_spec="$(echo ${mpi_desc} | awk '{print $1}')"
            mpi_hash="$(echo ${mpi_desc} | awk '{print $2}')"

            echo " --> marking explicit: ${mpi_desc}"
            spack mark --explicit "/${mpi_hash}"
        done
    done
}



# Define some complex package specs we'll use in multiple places
cat <<EOF > hpc-libs-versions.cfg
#---------------------------------------
# compiler and mpi versions to use when
# building hpc-libs
# (automatically generated by ${0})

MPICHS=( 'mpich@4' )
OPENMPIS=( 'openmpi@5' )
INTELMPIS=( 'intel-oneapi-mpi@2021' )
GCCS=( 'gcc@11.4.0' 'gcc@=12.3.0' 'gcc@13.2.0' )
ONEAPIS=( 'oneapi@=2023.2.4' )
INTELS=( 'intel@=2021.10.0' )
NVHPCS=( 'nvhpc@=24.3' )
MPTS=( 'mpt@=2.26' )

unset MPIS COMPS SPKGS PPKGS
MPIS=("\${MPICHS[@]}" "\${OPENMPIS[@]}" "\${INTELMPIS[@]}" )
COMPS=("\${GCCS[@]}" "\${ONEAPIS[@]}" "\${INTELS[@]}") #"\${NVHPCS[@]}")
#---------------------------------------

EOF

cat hpc-libs-versions.cfg

source hpc-libs-versions.cfg || { echo "ERROR: cannot source hpc-libs-versions.cfg!!"; exit 1; }

#--------------------------------------------------------------------------------
# phase 1 - install initial envrionment
#           including only MPIs with 'spack add'
#--------------------------------------------------------------------------------
activate_env
#spack mark --all --implicit
show_spack_configs
spack compilers
cat <<EOF
 -------------------------------------------------------------------------------
| ${spack_env} - phase 1 - installing
|    MPIS=( ${MPIS[@]} )
|  x COMPS=( ${COMPS[@]} )
 -------------------------------------------------------------------------------
EOF
comp_mpis_loop
spack concretize --fresh || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# clean any cruft from last step before moving on, to not fill our build stage
spack clean -s

# run a number of installs in the background
build_spack_pkgs
#--------------------------------------------------------------------------------



#--------------------------------------------------------------------------------
# phase 2 - with the previously installed MPIs now fixed,
#           install additional libraries
#--------------------------------------------------------------------------------
SPKGS=('hdf5~mpi')
SPGGS+=('highfive~mpi ^hdf5~mpi')
SPKGS+=('netcdf~mpi ^hdf5~mpi')
SPKGS+=('boost')

PPKGS=('hdf5+mpi')
PPKGS+=('mpl') # 'netcdf+mpi')
cat <<EOF
 -------------------------------------------------------------------------------
| ${spack_env} - phase 2 - installing
|    COMPS=( ${COMPS[@]} )
|  x SPGS=( ${SPKGS[@]} )
|
|    COMPS=( ${COMPS[@]} )
|  x MPIS=( ${MPIS[@]} )
|  x PPKGS=( ${PPKGS[@]} )
 -------------------------------------------------------------------------------
EOF
comp_spkg_ppkg_loop
spack concretize --fresh || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# clean any cruft from last step before moving on, to not fill our build stage
spack clean -s

# run a number of installs in the background
build_spack_pkgs
#--------------------------------------------------------------------------------



#--------------------------------------------------------------------------------
# make sure our desired MPIs are listed as explicit packages so we get modules.
# (I've seen them 'disappear' - particularly when iterating on this and later scripts)
mark_mpis_explicit

my_spack_refresh_lmod -y
#--------------------------------------------------------------------------------


# Reference:
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents +mpi
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents openmpi mpich intel-oneapi-mpi
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents %gcc@11.4.0
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents %gcc@13.2.0
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents %intel
# [Rocky8-Testbed-hpc-libs]$ spack uninstall --all --dependents %oneapi
# [Rocky8-Testbed-hpc-libs]$ spack gc
