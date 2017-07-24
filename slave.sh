#! /bin/bash

set -euo pipefail

main() {
    declare filename="${1-}" pkgname="${2-}" rversion="${3-}"

    # Everything is relateive to user's HOME
    cd

    # Set up environment variables, check arguments
    source rhub-env.sh

    export PATH=/opt/csw/bin:$PATH:/opt/R/R-3.4.1-patched-gcc/bin

    # Set R temporary directory
    mkdir $HOME/Rtemp
    export TMPDIR=$HOME/Rtemp

    echo "Setting up R environment"
    setup_r_environment

    echo "Setting up Xvfb"
    setup_xvfb

    echo ">>>>>============== Installing package dependencies"
    install_package_deps

    echo ">>>>>============== Running R CMD check"
    run_check
    echo ">>>>>============== Done with R CMD check"

    echo "Cleaning up Xvfb"
    cleanup_xvfb
}

setup_r_environment() {
    mkdir -p R
    echo >> .Rprofile 'options(repos = c(CRAN = "https://cran.r-hub.io"))'
    echo >> .Rprofile '.libPaths("~/R")'

    # BioC
    R -q -e "source('https://bioconductor.org/biocLite.R')"
    echo >> .Rprofile 'options(repos = BiocInstaller::biocinstallRepos())'
    echo >> .Rprofile 'unloadNamespace("BiocInstaller")'

    # Better tar, make
    export TAR=/opt/csw/bin/gtar
    export MAKE=/opt/csw/bin/gmake
}

install_package_deps() {
    R -q -e 'source("https://install-github.me/r-lib/remotes")'
    R -q -e "remotes::install_local('${filename}', dependencies = TRUE, INSTALL_opts = '--build')"
}

setup_xvfb() {
    # Random display between 1 and 100
    export DISPLAY=":$(($RANDOM / 331 + 1))"
    /usr/openwin/bin/Xvfb "${DISPLAY}" -dev vfb screen 1024x768x24 &
}

cleanup_xvfb() {
    kill -9 $(ps -ef | grep 'Xsun.*dev vfb' | grep -v grep |
		     awk '{ print $2; }') || true
}

run_check() {
    R CMD check $checkArgs -l ~/R $filename
}

[[ "$0" == "$BASH_SOURCE" ]] && ( main "$@" )
