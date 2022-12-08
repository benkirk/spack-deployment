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
#spack_lmod_root=${spack_clone_path}/share/spack/lmod/${spack_env}
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
      link_type: hardlink

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
          - gcc@12.2.0
          - gcc@11.3.0
        core_compilers:
          - ${spack_core_compiler}
        core_specs:
          - gcc
          - intel-oneapi-compilers
          - intel-parallel-studio
          - julia
          - llvm
        all:
          environment:
            set:
              '{name}_ROOT': '{prefix}'
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
          intel-oneapi-compilers: 'oneapi/{version}'
          intel-oneapi-mkl: 'intel-mkl/{version}'
          intel-oneapi-tbb: 'intel-tbb/{version}'
          r: 'R/{version}'
          mutationpp: 'mutation++/{version}'

  compilers:
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

  packages:
    librsvg:
      #buildable: False
      externals:
      - spec: librsvg@2.40.20
        prefix: /usr
    all:
      compiler: [${spack_core_compiler}]
      variants: [~mpi, +fortran] # make sure mpi doesn't sneak in through hdf5 (to paraview), or any sub-package.  enable fortran where applicable.

  specs:

    - anaconda2
    - anaconda3
    - apptainer~suid ^go@1.18
    - autoconf-archive
    - autoconf@2.69
    - autoconf@2.71 # https://community.intel.com/t5/Intel-Fortran-Compiler/ifx-2021-1-beta04-HPC-Toolkit-build-error-with-loopopt/m-p/1184181
    - automake@1.16.5
    - bash@5.1
    - binutils+ld
    - bison@3.8
    - bzip2
    - cantera ^intel-oneapi-mkl # 95% of the time just 'cantera' went off without a hitch in my experimentation.  then it tried to use nvhpc for BLAS & failed.  don't let it, manually specify mkl.
    - cgns
    - cmake@3.24
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
    - gmake@4.3
    - gmsh+eigen+openmp
    - gnuplot+X
    - go@1.18 # required for podman, might as well install it as a root spec and get a module for it...
    - hwloc
    #- imagemagick@7.0.8-7 ^librsvg@2.40.20 # the librsvg dependency had build issues, so cowardly fall back to the OS version (specified above as an 'external')
    - intel-oneapi-mkl
    - intel-oneapi-tbb
    - julia@1.7 ^llvm@12.0.1%${spack_core_compiler} # julia requires its own patched LLVM, don't get too frustrated if trying to reconcile this with any LLVM previously installed.
    - julia@1.8 ^llvm@13.0.1%${spack_core_compiler} # julia requires its own patched LLVM, don't get too frustrated if trying to reconcile this with any LLVM previously installed.
    - less
    - libfuse
    #- librsvg@2.44.14 ^libxml2+python@3.9
    - libszip
    - libtool@2.4.7
    - libxml2
    - lmod
    - m4@1.4.19
    - mercurial
    - miniconda2
    - miniconda3
    - mutationpp
    - ncurses
    - numactl
    - openjdk
    - openssh
    - pandoc
    - parallel
    - paraview+qt ^protobuf@3.21 # +python had issues, specify protobuf version to prevent erroneous 'Warning: There is no checksum on file to fetch protobuf@21.1 safely.' (21.1 is not a thing, so why is it looking for it...?)
    - pdsh
    - perl%${spack_core_compiler} # perl also gets built with older gcc via julia above, so fully specify so this makes it into the 'root' of our environment.
    - pkgconf
    - podman ^go@1.18
    - qt@5.15 # QT version that matches paraview, might as well install this since we will build it...
    - r@4.2+X+rmath
    - readline
    - rsync@3.2.4
    - ruby
    - scons
    - screen
    - slurm
    - sqlite
    - squashfs
    - squashfuse
    - strace@5.17
    - subversion
    - tar@1.34
    - tcl
    - tcsh
    #- tecplot
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
    - zsh
EOF

spack env remove -y ${spack_env} 2>/dev/null
spack mark --all --implicit
spack env create ${spack_env} ./${spack_yaml} || { cat ./${spack_yaml}; exit 1; }
spack env activate ${spack_env}
spack external find --not-buildable openssl ncurses #perl
spack config blame concretizer && spack config blame packages && spack config blame config # show our current configuration, with what comes from where
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

#exit 1

# populate our source cache mirror
spack mirror create --directory ${spack_source_cache} --all

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
