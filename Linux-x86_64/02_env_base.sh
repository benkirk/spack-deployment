#!/usr/bin/env bash
set +x
#----------------------------------------------------------------------------
# environment
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[ -f ${SCRIPTDIR}/spack_setup.sh ] && . ${SCRIPTDIR}/spack_setup.sh || \
    { echo "cannot locate ${SCRIPTDIR}/spack_setup.sh"; exit 1; }
#----------------------------------------------------------------------------

spack_env="${spack_deployment}-base"
spack_yaml="spack-${spack_env}.yaml"

echo "Configuring ${spack_env} from ${spack_yaml} in $(pwd)"

cat >${spack_yaml} <<EOF
spack:
  config:
    build_stage: ${spack_build_stage_path}
    install_tree:
      root: ${spack_clone_path}/${spack_env}
      projections:
          all: '{name}/{version}-{hash:7}'

  concretizer:
    unify: false

  view:
    base:
      root: ${spack_view_path}/${spack_env}
      projections:
        all: '{name}/{version}'
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
          environment:
            set:
              '{name}_ROOT': '{prefix}'
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

  packages:
    all:
      compiler: [${spack_core_compiler}]
      variants: [~mpi, +fortran] # make sure mpi doesn't sneak in through hdf5 (to paraview), or any sub-package.  enable fortran where applicable.

  specs:

    - apptainer~suid
    - autoconf-archive
    - autoconf@2.69
    - autoconf@2.71 # https://community.intel.com/t5/Intel-Fortran-Compiler/ifx-2021-1-beta04-HPC-Toolkit-build-error-with-loopopt/m-p/1184181
    - automake@1.16.5
    - bash@5
    - bc
    - binutils+ld
    - bison
    - bzip2
    #- cantera ^intel-oneapi-mkl
    - cgns
    - charliecloud #+squashfuse
    - cmake
    - curl
    - diffutils
    - doxygen+graphviz
    - eigen
    - emacs+X+tls toolkit=gtk
    - findutils
    - flex
    - gawk
    - gdb
    - gdbm
    - gettext
    - git
    - gimp ^highway@1.0.4 # 1.0.7: Error: no such instruction: vmovw %xmm1,12(%r13) etc...
    - gmake
    #- gmsh+eigen+openmp cxxflags="-fpermissive"
    - gnuplot+X
    - imagemagick
    - intel-oneapi-mkl
    - intel-oneapi-tbb
    - intel-oneapi-vtune
    #- julia@1.8 ^llvm@13.0.1%${spack_core_compiler} # julia requires its own patched LLVM, don't get too frustrated if trying to reconcile this with any LLVM previously installed.
    - libevent
    - libszip
    - libtirpc
    - libtool
    - libxml2
    - lmod
    - m4
    - mercurial
    - meson
    - miniconda3
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
    - pdsh
    - perl%${spack_core_compiler} # perl also gets built with older gcc via julia above, so fully specify so this makes it into the 'root' of our environment.
    - pkgconf
    - podman@4
    - qt@5.15 # QT version that matches paraview, might as well install this since we will build it...
    - r+X
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
    #- tecplot
    - texinfo
    - texlive
    - tk
    - tmux
    - util-linux-uuid
    - util-macros
    - valgrind~boost
    - vim+gui features=huge
    - wget
    - xz
    - zlib
    - zlib-ng
    - zsh
EOF

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
#spack external find --not-buildable openssl ncurses #perl
for arg in repos mirrors concretizer packages config modules compilers; do
    spack config blame ${arg} && echo && echo # show our current configuration, with what comes from where
done
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
for bg_inst in $(seq 1 ${n_concurrent_installs}); do
    spack install ${spack_install_flags} || [ "x${spack_install_flags}" != "x${spack_install_flags_no_cache}" ] && spack install ${spack_install_flags_no_cache} &
done
# run a single install in the foreground.  try with our build flags, which could use a binary cache,
# but fall back to a --no-cache attempt if necessary
spack install ${spack_install_flags} || spack install ${spack_install_flags_no_cache} || exit 1
wait

# build/refresh the lmod module tree
my_spack_refresh_lmod -y
