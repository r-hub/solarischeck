#! /bin/bash

sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
    case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
    (return 0 2>/dev/null) && sourced=1
else
    # All other shells: examine $0 for known shell binary filenames
    # Detects `sh` and `dash`; add additional shell filenames as needed.
    case ${0##*/} in sh|dash) sourced=1;; esac
fi

function install_r_opencsw() {
    echo "== INSTALLING R ==================================="
    sudo pkgutil -y -i libreadline7
    sudo pkgutil -y -i curl
    sudo pkgutil -t https://files.r-hub.io/opencsw -y -i r_base
}

function install_sysreqs() {
    (
	set -e
	tools=$(cat sysreqs.txt)
	sudo pkgutil -y -i $tools
    )
}

function install_tex() {
    sudo pkgutil -y -i \
	 texlive_base \
	 texlive_binaries \
	 texlive_common \
	 texlive_fonts_extra \
	 texlive_fonts_recommended \
	 texlive_latex_base \
	 texlive_latex_base_binaries \
	 texlive_latex_extra \
	 texlive_latex_extra_binaries \
	 texlive_latex_recommended
}

function install_r_hub_client() {
    curl -O -C - https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.2/swarm-client-2.2-jar-with-dependencies.jar
}

function main() {
    install_r_opencsw
    install_sysreqs
    install_tex
}

if [ "$sourced" = "0" ]; then
    set -e
    main
fi
