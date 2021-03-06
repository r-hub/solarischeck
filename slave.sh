#! /bin/bash

set -euo pipefail

main() {
    declare filename="${1-}" pkgname="${2-}" rversion="${3-}" ods="${4-}"

    # Everything is relateive to user's HOME
    cd

    # Remotes config, do not use extra packages, do not error out on
    # warnings
    export R_REMOTES_STANDALONE=true
    export R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

    # Set up environment variables
    # We need to export them, because R will run in a sub-shell
    # The rhubdummy variable is there, in case rhub-env.sh is empty,
    # and then export would just list the exported variables
    source rhub-env.sh
    export rhubdummy $(cut -f1 -d= < rhub-env.sh)

    export PATH=/opt/csw/sbin:/opt/csw/bin:/bin:/sbin:/usr/sbin:/usr/bin:/usr/sfw/bin:/usr/sfw/sbin:/usr/ccs/bin
    export PKG_CONFIG_PATH=/opt/csw/lib/pkgconfig

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
    run_check "${ods}"
    echo ">>>>>============== Done with R CMD check"

    echo "Cleaning up Xvfb"
    cleanup_xvfb
}

setup_r_environment() {
    mkdir -p R
    echo >> .Rprofile 'options(repos = c(CRAN = "https://cloud.r-project.org"))'
    echo >> .Rprofile '.libPaths("~/R")'

    # BioC
    R -q -e "install.packages('BiocManager')"
    echo >> .Rprofile 'options(repos = BiocManager::repositories())'
    echo >> .Rprofile 'unloadNamespace("BiocManager")'

    # Better tar, make
    export TAR=/opt/csw/bin/gtar
    export MAKE=/opt/csw/bin/gmake
}

install_package_deps() {
    R -q -e 'source("https://install-github.me/r-lib/remotes@r-hub")'
    R -q -e "remotes::install_local('${filename}', dependencies = TRUE, INSTALL_opts = '--build')"
}

setup_xvfb() {
    # Random display between 1 and 100
    export DISPLAY=":$(($RANDOM / 331 + 1))"
    /usr/X11R6/bin/Xvfb "${DISPLAY}" &
}

cleanup_xvfb() {
    if [ -n "$DISPLAY" ]; then
	kill -9 $(ps -ef | grep "Xvfb $DISPLAY" | grep -v grep |
			 awk '{ print $2; }') || true
    fi
}

run_check() {
    declare ods="${1-}"
    R=""
    if [[ -n "$ods" ]]; then R=$ODSR; fi
    if [[ -z "$R" ]]; then R=R; fi
    if [[ "$R" != "R" ]]; then echo Using R at "$R"; fi
    $R CMD check $checkArgs -l ~/R $filename
}

[[ "$0" == "$BASH_SOURCE" ]] && ( main "$@" )
