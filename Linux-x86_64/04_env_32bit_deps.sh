#!/usr/bin/env bash

#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && . ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh}"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-baseos-32bit-deps"
spack_yaml="spack-${spack_env}.yaml"

echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

sys_gcc_vers=$(echo "${spack_system_compiler}" | cut -d '@' -f2-)

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
          - lmod
        core_compilers:
          - None
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
      link_type: symlink

  compilers:
  - compiler:
      spec: gcc@${sys_gcc_vers}-m32
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
      compiler: [gcc@${sys_gcc_vers}-m32]
      variants: [~mpi, +fortran] # make sure mpi doesn't sneak in through hdf5 (to paraview), or any sub-package.  enable fortran where applicable.


EOF

my_build_fixed_externals \
    ${spack_view_path}/${spack_deployment}-base \
    bc cmake gmake curl perl tar \
    && echo "Fixed Externals:" && cat fixed_externals.yaml | tee -a ${spack_yaml}

cat >>${spack_yaml} <<EOF
  specs:
    - lmod
    - boost+atomic+chrono+date_time+filesystem+graph+json+log+math~mpi+multithreaded+program_options~python+random+regex+serialization+shared+signals+stacktrace+system+timer cxxstd=11
    - hdf5~mpi+szip+hl+cxx~fortran
    - zlib
    - zlib-ng
    - bzip2
    - unzip
    - xz
EOF

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
