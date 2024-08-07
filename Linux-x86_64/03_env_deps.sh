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
          #- ${spack_core_compiler}
          - None
        all:
          autoload: direct
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
      link_type: symlink

  compilers:
  - compiler:
      spec: gcc@13.2.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/13.2.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/13.2.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/13.2.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/13.2.0/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

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

  - compiler:
      spec: gcc@10.5.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.5.0/bin/gcc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.5.0/bin/g++
        f77: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.5.0/bin/gfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/gcc/10.5.0/bin/gfortran
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
      spec: nvhpc@24.3
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvc++
        f77: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvfortran
        fc: ${spack_view_path}/${spack_deployment}-compilers/nvhpc/24.3/Linux_x86_64/24.3/compilers/bin/nvfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64

  - compiler:
      spec: oneapi@2023.2.4
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/icx
        cxx: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/icpx
        f77: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/ifx
        fc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers/2023.2.4/compiler/latest/linux/bin/ifx
      flags:
        cflags: -lpthread
        cxxflags: -lpthread
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-base/gmake/4.3/bin
      extra_rpaths:
        - ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/lib64

  - compiler:
      spec: intel@2021.10.0
      paths:
        cc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers-classic/2021.10.0/bin/icc
        cxx: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers-classic/2021.10.0/bin/icpc
        f77: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers-classic/2021.10.0/bin/ifort
        fc: ${spack_view_path}/${spack_deployment}-compilers/intel-oneapi-compilers-classic/2021.10.0/bin/ifort
      flags:
        cflags: -lpthread
        cxxflags: -lpthread
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment:
        prepend_path:
          PATH: ${spack_view_path}/${spack_deployment}-compilers/gcc/12.3.0/bin
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

  packages:
    hdf5:
      variants: [+fortran, +cxx, +szip, +hl]
    openmpi:
      require: [+legacylaunchers, schedulers=slurm]
    mpich:
      require: [+slurm]
    all:
      compiler: [${spack_core_compiler}]
EOF

my_build_fixed_externals \
    ${spack_view_path}/${spack_deployment}-base \
    cmake autoconf libtool automake slurm openssh perl findutils diffutils m4 curl tar pkgconf util-macros libszip \
    gmake gettext numactl libxml2 zlib zlib-ng zstd xz ncurses tcl readline bzip2 gdbm util-linux-uuid sqlite intel-oneapi-mkl \
    openssl libevent texinfo autoconf-archive \
    && echo "Fixed Externals:" && cat fixed_externals.yaml | tee -a ${spack_yaml}
cat >>${spack_yaml} <<EOF
  specs:
    - lmod%${spack_core_compiler}
EOF

# function to loop over outer prodcut of (compiler)x(serial packages) & (compiler)x(mpis)x(parallel packages)
comp_spkg_ppkg_loop() {

    for comp in "${COMPS[@]}"; do
        for spkg in "${SPKGS[@]}"; do
            echo "    - $spkg %$comp" >> ${spack_yaml}.tmp
        done
        for mpi in "${MPIS[@]}"; do
            echo "    - $mpi %$comp" >> ${spack_yaml}.tmp
            for ppkg in "${PPKGS[@]}"; do
                echo "    - $ppkg %$comp ^$mpi %$comp" >> ${spack_yaml}.tmp
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

MPICHS=( 'mpich@4+slurm' )
OPENMPIS=( 'openmpi@5+legacylaunchers schedulers=slurm' )
GCCS=( 'gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0' 'gcc@13.2.0' )
ONEAPIS=( 'oneapi@2023.2.4' )
INTELS=( 'intel@2021.10.0' )
NVHPCS=( 'nvhpc@24.3' )
MPTS=( 'mpt@2.26' )

unset MPIS COMPS SPKGS PPKGS
MPIS=("\${MPICHS[@]}" "\${OPENMPIS[@]}")
COMPS=("\${GCCS[@]}" "\${ONEAPIS[@]}" "\${INTELS[@]}") #"\${NVHPCS[@]}")
EOF

. hpc-apps-versions.cfg || { echo "ERROR: cannot source hpc-apps-versions.cfg!!"; exit 1; }


BOOST183='boost@1.83+atomic+chrono+date_time+filesystem+graph+json+log+math~mpi+multithreaded+program_options~python+random+regex+serialization+shared+signals+stacktrace+system+timer cxxstd=11'
BOOST='boost+atomic+chrono+date_time+filesystem+graph+json+log+math~mpi+multithreaded+program_options~python+random+regex+serialization+shared+signals+stacktrace+system+timer cxxstd=11'
HDF5='hdf5+mpi~fortran+cxx+szip+hl'

SPKGS=('hdf5~mpi+fortran+cxx+szip+hl' 'openblas threads=openmp' 'highfive~mpi ^hdf5~mpi')
SPKGS+=("${BOOST}")
SPKGS+=("${BOOST183}")
SPKGS+=('netcdf~mpi ^hdf5~mpi')

PPKGS=( "${HDF5}" 'hpl ^intel-oneapi-mkl' 'osu-micro-benchmarks' 'mpl' )
comp_spkg_ppkg_loop

unset SPKGS
COMPS=("${GCCS[@]}")
PPKGS=('mpifileutils~gpfs~lustre+xattr' 'hpcg')
comp_spkg_ppkg_loop

### BSK: # Dakota & gcc@13 dont mix
### BSK: COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0')
### BSK: PPKGS=("dakota@6.18+mpi ^${BOOST183}")
### BSK: unset SPKGS
### BSK: comp_spkg_ppkg_loop
### BSK:
### BSK: COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0' 'gcc@13.2.0' 'oneapi@2023.2.4')
### BSK: PPKGS=('petsc@3.17+hypre~hdf5~metis+mpi+openmp+scalapack+shared~suite-sparse~superlu-dist ^intel-oneapi-mkl')
### BSK: comp_spkg_ppkg_loop
### BSK:
### BSK: COMPS=('gcc@10.5.0' 'gcc@11.4.0' 'gcc@12.3.0' 'gcc@13.2.0')
### BSK: PPKGS=('petsc@3.16+hypre~hdf5~metis+mpi+openmp+shared~suite-sparse~superlu-dist ^intel-oneapi-mkl')
### BSK: comp_spkg_ppkg_loop
### BSK:
### BSK: COMPS=("${spack_system_compiler}")
### BSK: unset MPIS
### BSK: SPKGS=('netcdf~mpi ^hdf5~mpi')
### BSK: unset PPKGS
### BSK: comp_spkg_ppkg_loop

# Weed out all the duplicates
cat ${spack_yaml}.tmp | sort | uniq >> ${spack_yaml} && rm -f ${spack_yaml}.tmp

# debug the yaml file
cat ${spack_yaml} #&& exit 0

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
