#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && . ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-compiler-deps"
spack_yaml="spack-${spack_env}.yaml"

echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

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
          - ${spack_core_compiler}
        all:
          environment:
            set:
              '{name}_ROOT': '{prefix}'
        projections:
          hdf5+mpi: '{name}-mpi/{version}'

  view:
    my_view:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}-{hash:7}-{compiler.name}-{compiler.version}'
        ^mpi: '{name}/{version}-{hash:7}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
      link: roots
      #link_type: hardlink
      link_type: symlink

  compilers:
  - compiler:
      spec: gcc@12.3.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: gcc@11.4.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.4.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.4.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.4.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/11.4.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

#   - compiler:
#       spec: gcc@10.4.0
#       paths:
#         cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.4.0/bin/gcc
#         cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.4.0/bin/g++
#         f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.4.0/bin/gfortran
#         fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.4.0/bin/gfortran
#       flags: {}
#       operating_system: ${os_version}
#       target: x86_64
#       modules: []
#       environment: {}
#       extra_rpaths: []

  - compiler:
      spec: nvhpc@23.9
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers//nvhpc/23.9/Linux_x86_64/23.9/compilers/bin/nvc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/23.9/Linux_x86_64/23.9/compilers/bin/nvc++
        f77: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/23.9/Linux_x86_64/23.9/compilers/bin/nvfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/23.9/Linux_x86_64/23.9/compilers/bin/nvfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  - compiler:
      spec: oneapi@2023.2.1
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.1/compiler/latest/linux/bin/icx
        cxx: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.1/compiler/latest/linux/bin/icpx
        f77: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.1/compiler/latest/linux/bin/ifx
        fc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.1/compiler/latest/linux/bin/ifx
      flags:
        # have Intel's compiler use our newer, not system gcc
        # https://spack.readthedocs.io/en/latest/getting_started.html#vendor-specific-compiler-configuration
        cflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
        cxxflags: -std=gnu++17 --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
        fflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-base/gmake/4.3/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64

#  - compiler:
#      spec: clang@15.0.4
#      paths:
#        cc: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/clang
#        cxx: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/clang++
#        f77: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/flang-new
#        fc: ${spack_view_path}/${spack_deployment}-compilers/llvm/15.0.4/bin/flang-new
#      flags: {}
#      operating_system: ${os_version}
#      target: x86_64
#      modules: []
#      environment:
#        prepend_path:
#          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin
#      extra_rpaths:
#        - ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64

#  - compiler:
#      spec: aocc@3.2.0
#      paths:
#        cc: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/clang
#        cxx: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/clang++
#        f77: ${spack_view_path}/${spack_deployment}-compilers//aocc/3.2.0/bin/flang
#        fc: ${spack_view_path}/${spack_deployment}-compilers/aocc/3.2.0/bin/flang
#      flags:
#        # have AMD's compiler use our newer, not system gcc
#        # https://spack.readthedocs.io/en/latest/getting_started.html#vendor-specific-compiler-configuration
#        cflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
#        cxxflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
#        fflags: --gcc-toolchain=${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0
#        # fix for d.lld: error: lib/.libs/libmpi.so: undefined reference to ceilf
#        ldflags: -lm
#      operating_system: ${os_version}
#      target: x86_64
#      modules: []
#      environment:
#        prepend_path:
#          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin
#      extra_rpaths:
#        - ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64

  definitions:

#  - amd_compilers:
#    - aocc@3.2.0
#
#  - clang_compilers:
#    - clang@15.0.4

  - gcc_compilers:
    - gcc@12.3.0
    - gcc@11.4.0
#    - gcc@10.4.0
#    - gcc@9.5.0

  - oneapi_compilers:
    - oneapi@2023.2.1

  - nvidia_compilers:
    - nvhpc@23.9

  - all_compilers:
    - \$amd_compilers
    - \$gcc_compilers
    - \$oneapi_compilers
    - \$nvidia_compilers

  - preferred_compilers:
    - \$gcc_compilers
    - \$oneapi_compilers
    - \$nvidia_compilers

  - mpis: [ 'mpich@4+slurm',
            'openmpi@4+legacylaunchers schedulers=slurm' ]

  - serial_packages: [ 'hdf5~mpi+fortran+cxx+szip+hl',
                       'openblas threads=openmp' ]

  - parallel_packages: [ 'hdf5+mpi~fortran+cxx+szip+hl',
                         'hpl ^intel-oneapi-mkl',
                         'osu-micro-benchmarks' ]

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
#      - [ 'mpifileutils~gpfs~lustre+xattr', 'hpcg' ]
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
MPIS=('mpich@4+slurm' 'openmpi@4+legacylaunchers schedulers=slurm')
#COMPS=('gcc@9.5.0' 'gcc@10.4.0' 'gcc@11.4.0' 'gcc@12.3.0' 'oneapi@2023.2.1' 'nvhpc@23.9')
COMPS=('gcc@11.4.0' 'gcc@12.3.0' 'oneapi@2023.2.1')
#COMPS=('gcc@11.4.0' 'gcc@12.3.0' 'oneapi@2023.2.1')
SPKGS=('hdf5~mpi+fortran+cxx+szip+hl' 'openblas threads=openmp')
PPKGS=('hdf5+mpi~fortran+cxx+szip+hl' 'hpl ^intel-oneapi-mkl' 'osu-micro-benchmarks')
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

COMPS=('gcc@11.4.0' 'gcc@12.3.0')
PPKGS=('mpifileutils~gpfs~lustre+xattr' 'hpcg')
for comp in "${COMPS[@]}"; do
    for mpi in "${MPIS[@]}"; do
        echo "    - $mpi %$comp" >> ${spack_yaml}
        for ppkg in "${PPKGS[@]}"; do
            echo "    - $ppkg %$comp ^$mpi %$comp" >> ${spack_yaml}
        done
    done
done

cat >>${spack_yaml} <<EOF
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
EOF


my_build_fixed_externals \
    ${spack_view_path}/${spack_deployment}-base \
    cmake autoconf libtool automake slurm openssh perl findutils diffutils m4 curl tar pkgconf util-macros libszip \
    gettext numactl libxml2 zlib xz ncurses tcl readline bzip2 gdbm util-linux-uuid sqlite intel-oneapi-mkl \
    && echo "Fixed Externals:" && cat fixed_externals.yaml | tee -a ${spack_yaml}

# debug the yaml file
#cat ${spack_yaml} && exit 0

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
for arg in repos mirrors concretizer packages config modules compilers; do
    spack config blame ${arg} && echo && echo # show our current configuration, with what comes from where
done
spack compilers

spack concretize --fresh \
    || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# clean any cruft from last step before moving on, to not fill our build stage
spack clean -s

# run a number of installs in the background
for bg_inst in $(seq 1 ${n_concurrent_installs}); do
    spack install ${spack_install_flags} || [ "x${spack_install_flags}" != "x${spack_install_flags_no_cache}" ] && spack install ${spack_install_flags_no_cache} &
done
# run a single install in the foreground.  try with our build flags, which could use a binary cache,
# but fall back to a --no-cache attempt if necessary
spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
wait

# build/refresh the lmod module tree
my_spack_refresh_lmod -y


# $ spack -e FSL-compiler-deps find -Lv cmake
#   ==> 4 installed packages
#   -- linux-centos7-x86_64 / gcc@11.4.0 ----------------------------
#   yrszczdtiitopfe5ner4qilpilzbb6d5 cmake@3.23.3~doc+ncurses+ownlibs~qt build_type=Release
#   dsq7l6xf4xl6v3gqyppofgmmhpez5wo4 cmake@3.23.3~doc+ncurses+ownlibs+qt build_type=Release
#   a3guofdikiycw4za73sjfmmuwj5ltjwr slurm@21-08-8-2~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc
#   jcefrlaliaqws6iiz2oepi3mpolrlotc slurm@21-08-8-2~gtk~hdf5~hwloc~mariadb~pmix+readline~restd sysconfdir=PREFIX/etc
