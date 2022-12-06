#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && . ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

# navigate to our clone directory and set up the spack environment
spack_clone_path=${spack_clone_path_deps} \
    && cd ${spack_clone_path} && pwd && . share/spack/setup-env.sh || exit 1

spack_env="${spack_deployment}-compiler-deps"
spack_yaml="spack-${spack_env}.yaml"
echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

#[ -d ${spack_source_cache}/_source-cache/ ] && spack mirror add mysrcmirror ${spack_source_cache} && spack mirror list
#[ -d ${spack_build_cache}/build_cache/    ] && spack mirror add mybinmirror ${spack_build_cache}  && spack mirror list

# use the base root as an upstream, if different than the deps root
[ "x${spack_clone_path_base}" != "x${spack_clone_path_deps}" ] && cat > etc/spack/upstreams.yaml <<EOF
upstreams:
  spack-instance-base:
    install_tree: ${spack_clone_path_base}/${spack_deployment}-base
EOF

cat >${spack_yaml} <<EOF
spack:

  config:
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_clone_path}/${spack_env}
      #padded_length: 112
      projections:
          all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
          ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'

  concretizer:
    unify: false

  packages:
    hdf5:
      variants: [+fortran, +cxx, +szip, +hl]
    hpe-mpt:
      buildable: False
      externals:
      - spec: hpe-mpt@2.26
        prefix: /software/x86_64/mpi/hpe-mpt-2.26
      - spec: hpe-mpt@2.24
        prefix: /software/x86_64/mpi/hpe-mpt-2.24
    all:
      compiler: [${spack_core_compiler}]

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
        all:
          environment:
            set:
              '{name}_ROOT': '{prefix}'
        projections:
          hdf5+mpi: '{name}-mpi/{version}'
          #hdf5+mpi+fortran+cxx+hl+szip: '{name}-mpi/{version}'

  view:
    my_view:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
        ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
      link: roots
      link_type: hardlink

  compilers:
  - compiler:
      spec: gcc@12.2.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.2.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.2.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.2.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.2.0/bin/gfortran
      flags: {}
      operating_system: centos7
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []
  - compiler:
      spec: gcc@11.3.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin/gfortran
      flags: {}
      operating_system: centos7
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: nvhpc@22.9
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/22.9/Linux_x86_64/22.9/compilers/bin/nvc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/22.9/Linux_x86_64/22.9/compilers/bin/nvc++
        f77: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/22.9/Linux_x86_64/22.9/compilers/bin/nvfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/22.9/Linux_x86_64/22.9/compilers/bin/nvfortran
      flags: {}
      operating_system: centos7
      target: x86_64
      modules:
        - cuda
      # nvhpc needs to be able to find cuda
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin
#          PATH: ${spack_view_path}/${spack_deployment}-compilers/cuda/6.5.14/bin
#        set:
#          CUDA_HOME: ${spack_view_path}/${spack_deployment}-compilers/cuda/6.5.14
      extra_rpaths: []

  - compiler:
      spec: oneapi@2022.2.1
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2022.2.1/compiler/latest/linux/bin/icx
        cxx: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2022.2.1/compiler/latest/linux/bin/icpx
        f77: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2022.2.1/compiler/latest/linux/bin/ifx
        fc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2022.2.1/compiler/latest/linux/bin/ifx
      flags:
        # have Intel's compiler use our newer, not system gcc
        # https://spack.readthedocs.io/en/latest/getting_started.html#vendor-specific-compiler-configuration
        cflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
        cxxflags: -std=gnu++17 --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
        fflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
      operating_system: centos7
      target: x86_64
      modules: []
      environment:
        set:
          INTEL_LICENSE_FILE: /software/x86_64/intel/license.dat
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-base/gmake/4.3/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64

  - compiler:
      spec: clang@15.0.4
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/clang
        cxx: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/clang++
        f77: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/flang-new
        fc: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/flang-new
      flags: {}
      operating_system: centos7
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64

  - compiler:
      spec: aocc@3.2.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/clang
        cxx: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/clang++
        f77: ${spack_view_path}/${spack_deployment}-compilers//aocc/3.2.0/bin/flang
        fc: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/flang
      flags:
        # have AMD's compiler use our newer, not system gcc
        # https://spack.readthedocs.io/en/latest/getting_started.html#vendor-specific-compiler-configuration
        cflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
        cxxflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
        fflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0
        # fix for d.lld: error: lib/.libs/libmpi.so: undefined reference to ceilf
        ldflags: -lm
      operating_system: centos7
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/11.3.0/lib64

  definitions:

  - amd_compilers:
    - aocc@3.2.0

  - clang_compilers:
    - clang@15.0.4

  - gcc_compilers:
    - gcc@12.2.0
    - gcc@11.3.0

  - oneapi_compilers:
    - oneapi@2022.2.1

  - nvidia_compilers:
    - nvhpc@22.9

  - all_compilers:
    - \$amd_compilers
    - \$gcc_compilers
    - \$oneapi_compilers
    - \$nvidia_compilers

  - preferred_compilers:
    - \$gcc_compilers
    - \$oneapi_compilers
    - \$nvidia_compilers

  - mpis: [ 'mpich@4.0.2+slurm',
            'openmpi@4.1.4+legacylaunchers schedulers=slurm' ]

  - serial_packages: [ 'hdf5~mpi+fortran+cxx+szip+hl',
                       'openblas threads=openmp' ]

  - parallel_packages: [ 'hdf5+mpi~fortran+cxx+szip+hl',
                         'hpcg',
                         'hpl ^intel-oneapi-mkl',
                         'osu-micro-benchmarks@6.2' ]

  specs:
    - lmod%${spack_core_compiler}
    #- osu-micro-benchmarks ^hpe-mpt@2.26
#    - matrix:
#      - [ \$mpis, \$serial_packages ]
#      - [ \$%all_compilers ]

#    - matrix:
#      - [ \$parallel_packages ]
#      - [ \$^mpis  ]
#      - [ \$%all_compilers ]
#
#    - matrix:
#      - [ 'mpifileutils@0.11.1' ]
#      - [ \$^mpis  ]
#      - [ \$%gcc_compilers ]

#    - matrix:
#      - [ 'petsc+fortran+hdf5+hypre~metis+mkl-pardiso+mpi+openmp+scalapack+shared+suite-sparse+superlu-dist+tetgen ^intel-oneapi-mkl ^openmpi' ]
#      - [ \$%gcc_compilers ]
#
#    - matrix:
#      - [ 'petsc+fortran+hdf5+hypre~metis+mkl-pardiso+mpi+openmp+scalapack+shared+suite-sparse~superlu-dist+tetgen ^intel-oneapi-mkl ^openmpi' ]
#      - [ \$%oneapi_compilers  ]
EOF

unset MPIS COMPS SPKGS PPKGS
MPIS=('mpich@4.0.2+slurm' 'openmpi@4.1.4+legacylaunchers schedulers=slurm')
COMPS=('gcc@11.3.0' 'gcc@12.2.0' 'oneapi@2022.2.1' 'nvhpc@22.9')
SPKGS=('hdf5~mpi+fortran+cxx+szip+hl' 'openblas threads=openmp')
PPKGS=('hdf5+mpi~fortran+cxx+szip+hl' 'hpl ^intel-oneapi-mkl' 'osu-micro-benchmarks@6.2')
for comp in "${COMPS[@]}"; do
    for spkg in "${SPKGS[@]}"; do
        echo "    - $spkg %$comp" >> ${spack_yaml}
    done
    for mpi in "${MPIS[@]}"; do
        echo "    - $mpi %$comp" >> ${spack_yaml}
        for ppkg in "${PPKGS[@]}"; do
            echo "    - $ppkg %$comp ^$mpi %$comp" >> ${spack_yaml}
        done
    done
done


my_build_fixed_externals \
    ${spack_view_path}/${spack_deployment}-base \
    cmake autoconf libtool automake slurm openssh perl findutils diffutils m4 curl tar pkgconf util-macros libszip \
    gettext hwloc numactl libxml2 zlib xz ncurses tcl readline bzip2 gdbm util-linux-uuid sqlite intel-oneapi-mkl \
    && echo "Fixed Externals:" && cat fixed_externals.yaml | tee -a ${spack_yaml}

# debug the yaml file
#cat ${spack_yaml} && exit 0

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
spack config blame concretizer && spack config blame config # show our current configuration, with what comes from where
spack compilers

spack concretize \
    || exit 1

# debug the concretize step
#exit 0

# clean any cruft from last step before moving on, to not fill our build stage
spack clean -s

# run a number of installs in the background
for bg_inst in $(seq 1 ${n_concurrent_installs}); do
    spack install ${spack_install_flags} &
done
# run a single install in the foreground.  try with our build flags, which could use a binary cache,
# but fall back to a --no-cache attempt if necessary
spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
wait

# build/refresh the lmod module tree
my_spack_refresh_lmod -y


# $ spack -e FSL-compiler-deps find -Lv cmake
#   ==> 4 installed packages
#   -- linux-centos7-x86_64 / gcc@11.3.0 ----------------------------
#   yrszczdtiitopfe5ner4qilpilzbb6d5 cmake@3.23.3~doc+ncurses+ownlibs~qt build_type=Release
#   dsq7l6xf4xl6v3gqyppofgmmhpez5wo4 cmake@3.23.3~doc+ncurses+ownlibs+qt build_type=Release
#   a3guofdikiycw4za73sjfmmuwj5ltjwr slurm@21-08-8-2~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc
#   jcefrlaliaqws6iiz2oepi3mpolrlotc slurm@21-08-8-2~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc
