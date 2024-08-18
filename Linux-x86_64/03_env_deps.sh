#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-hpc-apps"
spack_yaml="spack-${spack_env}.yaml"

echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

cat >${spack_yaml} <<EOF
spack:

  config:
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_pkg_install_path}
      projections:
          all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
          ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'

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


#my_build_fixed_pkgs \
my_build_fixed_externals \
    ${spack_pkg_install_path} \
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

# function to loop over outer prodcut of (compiler)x(serial packages) & (compiler)x(mpis)x(parallel packages)
comp_spkg_ppkg_loop() {

    for comp in "${COMPS[@]}"; do
        for spkg in "${SPKGS[@]}"; do
            echo "    - ${spkg} %${comp}" >> ${spack_yaml}.tmp
        done
        for mpi in "${MPIS[@]}"; do
            echo "    - ${mpi}%${comp}" >> ${spack_yaml}.tmp
            for ppkg in "${PPKGS[@]}"; do
                echo "    - ${ppkg} %${comp} ^${mpi}%${comp}" >> ${spack_yaml}.tmp
            done
        done
    done
}

rm -f ${spack_yaml}.tmp

# Define some complex package specs we'll use in multiple places
cat <<EOF > hpc-apps-versions.cfg
#---------------------------------------
# compiler and mpi versions to use when
# building hpc-apps
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

# library versions perhaps useful to pin within apps later
BOOST183='boost@=1.83.0' #+atomic+chrono+date_time+filesystem+graph+json+log+math~mpi+multithreaded+program_options~python+random+regex+serialization+shared+signals+stacktrace+system+timer cxxstd=11'
BOOST='boost' #+atomic+chrono+date_time+filesystem+graph+json+log+math~mpi+multithreaded+program_options~python+random+regex+serialization+shared+signals+stacktrace+system+timer cxxstd=11'
HDF5='hdf5+mpi+fortran+cxx+szip+hl'
#---------------------------------------

EOF

pwd
cat hpc-apps-versions.cfg

source hpc-apps-versions.cfg || { echo "ERROR: cannot source hpc-apps-versions.cfg!!"; exit 1; }

SPKGS=('hdf5~mpi')
SPGGS+=('highfive~mpi ^hdf5~mpi')
SPKGS+=('netcdf~mpi ^hdf5~mpi')
SPKGS+=("${BOOST}")
#SPKGS+=("${BOOST183}")

PPKGS=('hdf5+mpi')
PPKGS+=('netcdf+mpi' 'mpl') #'hpl' 'osu-micro-benchmarks' )
comp_spkg_ppkg_loop

# Weed out all the duplicates
cat ${spack_yaml}.tmp | sort | uniq >> ${spack_yaml} && rm -f ${spack_yaml}.tmp

# debug the yaml file
cat ${spack_yaml} #&& exit 0

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
show_spack_configs
spack compilers

spack concretize --fresh \
    || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# clean any cruft from last step before moving on, to not fill our build stage
spack clean -s

# run a number of installs in the background
build_spack_pkgs

# # build/refresh the lmod module tree.  Occasionaly (v.0.22.1?) the MPIs somehow erroneoulsy
# # became implicit along the way, and no module files were generated.  So explicitly mark then last,
# # just in case.
# for mpi in "${MPIS[@]}"; do
#     spack mark --all --explicit ${mpi}
# done
my_spack_refresh_lmod -y


# Now, we've installed all the MPIs we want in this environment.
# set mpi:buildable:False, this will force any/all apps installed
# later to use one of the existing MPIs instead of building a new one.
# - yep, seen that before...
#spack config add 'packages:mpi:buildable:False'
#spack config add 'packages:mpich:buildable:False'
#spack config add 'packages:openmpi:buildable:False'
