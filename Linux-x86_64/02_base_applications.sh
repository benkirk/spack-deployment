#!/usr/bin/env bash
set +x
#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && source ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-base"
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

  view:
    base:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}'
        cgt+dp: '{name}/{version}-dp'
        cgt~dp: '{name}/{version}-sp'
      link: roots
      link_type: symlink

  modules:
    default::
      enable::
        - lmod
      arch_folder: false
      roots:
        lmod: ${spack_lmod_root}
      lmod:
        exclude_implicits: true
        hash_length: 0
        exclude:
          - '%${spack_system_compiler}'
          - lmod
        include:
          - gcc@13
          - gcc@12
          - gcc@11
          - gcc@10
          - gcc@9
          - gcc@4
        core_compilers:
          - ${spack_core_compiler}
        core_specs:
          - gcc
          - intel-oneapi-compilers
          - intel-oneapi-compilers-classic
          - julia
          - llvm
        all:
          autoload: direct
          environment:
            set:
              '{name}_ROOT': '{prefix}'

        esp:
          environment:
            set:
              '{name}_ROOT': '{prefix}/EngSketchPad'

        julia:
          environment:
            set:
              'JULIA_PKG_USE_CLI_GIT': '1'

        # the tecplot module definition needs some help to find bin, and to set a sensible license file
        tecplot:
          environment:
            set:
              'TECHOME': '{prefix}'
              'TEC360HOME': '{prefix}'
              'teclmd_LICENSE': '27101@keys-fsl.jsc.nasa.gov'
            prepend_path:
              PATH: '{prefix}/360ex_{version}/bin'

        projections:
          all: '{name}/{version}'
          intel-oneapi-compilers: 'intel-oneapi/{version}'
          intel-oneapi-compilers-classic: 'intel-classic/{version}'
          intel-oneapi-mkl: 'intel-mkl/{version}'
          intel-oneapi-tbb: 'intel-tbb/{version}'
          intel-oneapi-vtune: 'intel-vtune/{version}'
          r: 'R/{version}'
          mutationpp: 'mutation/{version}'
          cgt+dp: '{name}/{version}-dp'
          cgt~dp: '{name}/{version}-sp'

  compilers:
  - compiler:
      spec: gcc@=${spack_core_gcc_version}
      paths:
        cc: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin/gcc
        cxx: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin/g++
        f77: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin/gfortran
        fc: ${spack_pkg_install_path}/gcc/${spack_core_gcc_version}/bin/gfortran
      flags: {}
      operating_system: ${os_version}
      target: x86_64
      modules: []
      environment: {}
      extra_rpaths: []

  packages:
    mpi:
      buildable: False # No MPIs at all in step-02

    opengl:
      buildable: False
      externals:
      - spec: opengl@4.5.0
        prefix: /usr

    all:
      compiler:: [${spack_core_compiler}]
      providers:
        blas::      [intel-oneapi-mkl]
        lapack::    [intel-oneapi-mkl]
        scalapack:: [intel-oneapi-mkl]
        tbb::       [intel-oneapi-tbb]

      variants: [~mpi, +fortran] # make sure mpi doesn't sneak in through hdf5 (to paraview), or any sub-package.  enable fortran where applicable.

  specs:

    - apptainer~suid
    - autoconf-archive
    - autoconf@=2.69
    - autoconf@=2.71 # https://community.intel.com/t5/Intel-Fortran-Compiler/ifx-2021-1-beta04-HPC-Toolkit-build-error-with-loopopt/m-p/1184181
    - automake@=1.16.5
    - bash@5
    - bazel
    - bazel@=4.2.1 ^openjdk ^python@3.8
    - bc
    - binutils+ld
    - bison
    - bzip2
    #- cantera ^intel-oneapi-mkl
    - cgns
    #- cgt~tecio+dp # tecio brings in boost which is having a problem
    #- cgt~tecio~dp  # sp is causing a view clash...
    - charliecloud+squashfuse
    - cmake
    - curl
    - diffutils
    - dos2unix
    - doxygen+graphviz
    - eigen
    - emacs+X+tls toolkit=gtk
    #- esp
    - findutils
    - flex
    - gawk
    - gdb
    - gdbm
    - gettext
    - ghostscript
    - git
    - gimp ^gettext+libxml2 ^highway@=1.0.4 # highway@=1.0.7: Error: no such instruction: vmovw %xmm1,12(%r13) etc...
    - gmake
    #- gmsh+eigen+openmp cxxflags="-fpermissive"
    - gnuplot+X
    - imagemagick
    - intel-oneapi-mkl
    - intel-oneapi-tbb
    - intel-oneapi-vtune
    #- julia
    - libevent
    - libfabric
    - libszip
    - libtirpc
    - libtool
    - libxml2
    - lmod
    - m4
    - matio
    - mercurial
    - meson
    - miniforge3@=24.3.0-0-Linux-x86_64
    #- mplayer
    - mutationpp
    - ncurses
    - ninja
    - numactl
    - openjdk
    - openssh
    - openssl
    - pandoc
    - parallel
    - paraview+qt
    - pdf2svg
    - pdsh
    - perl%${spack_core_compiler} # perl also gets built with older gcc via julia above, so fully specify so this makes it into the 'root' of our environment.
    - pkgconf
    - podman@4
    - python@3.8 # <-- required for VTK@8.2.1a later
    - python@3.9
    - python@3.10
    - python@3.11
    - python@3.12
    - py-ipython
    - qt@5.15 # QT version that matches paraview, might as well install this since we will build it...
    #- r+X
    - readline
    - rsync
    - ruby
    - scons
    - screen
    - slurm
    - sqlite
    - squashfs
    - squashfuse
    - strace
    - subversion
    - tar
    - tcl
    - tcsh
    - texinfo
    - texlive
    - tk
    - tmux
    - tree
    - ucx
    - util-linux-uuid
    - util-macros
    - valgrind~boost
    - vim+gui features=huge
    - wget
    - xxdiff
    - xz
    - zlib
    - zlib-ng
    - zsh
    - zstd
EOF
}  # < -- end custom_env_yaml_initialization()

activate_env
#spack mark --all --implicit
show_spack_configs
spack compilers

# occasionally, packages fail download with
# ==> Error: FetchError: All fetchers failed for ...
# this seems to happen especially for Julia. we can work around by creating a local 'mirror' populated with source
# tarballs, e.g.:
#    $ ls -lR my_mirror/
#    my_mirror/
#    my_mirror/julia
#    my_mirror/julia/julia-1.7.3.tar.gz
#
# here we simply need to tell spack to use such a mirror.
[ -d ${HOME}/.spack/my_mirror ] \
    && spack mirror add my_mirror file://${HOME}/.spack/my_mirror \
    && spack mirror list

spack concretize --fresh \
    || exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

# run a number of installs in the background
build_spack_pkgs

# build/refresh the lmod module tree
my_spack_refresh_lmod -y
