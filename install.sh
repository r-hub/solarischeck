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

function install_tools() {
    /opt/csw/bin/pkgutil -y -i curl gcc5core gcc5gfortran gcc5g++ \
			 libreadline_dev libiconv_dev libz_dev liblzma_dev \
			 libpcre_dev libcurl_dev libssl_dev libssh2_dev \
			 libcares_dev openldap_dev libbrotli_dev \
			 libkrb5_dev libcairo_dev librtmp_dev gmake gtar
}

function download_r_devel {
    /opt/csw/bin/curl -O https://stat.ethz.ch/R/daily/R-devel.tar.gz
    gzip -dc R-devel.tar.gz | tar xf -
}

function download_r_patched {
    /opt/csw/bin/curl -O https://stat.ethz.ch/R/daily/R-patched.tar.gz
    gzip -dc R-patched.tar.gz | tar xf -
}

function compile_r_patched {
    (
	set -e
	if [ -e /opt/R/R-patched ]; then
	    >&2 echo /opt/R/R-patched already exists, exiting
	    exit 1
	fi
	cd R-patched
	if [ ! -e config.site.orig ]; then
	    mv config.site config.site.orig
	fi
	cp ../config.site .
	export LD_LIBRARY_PATH=/opt/csw/lib
	export PKG_CONFIG_PATH=/opt/csw/lib/pkgconfig
	export PATH=$PATH:/usr/ccs/bin
	export MAKE=/opt/csw/bin/gmake
	export TAR=/opt/csw/bin/gtar
	./configure -C --with-internal-tzcode \
		    --prefix=/opt/R/R-patched
	/opt/csw/bin/gmake
	/opt/csw/bin/gmake install
    )
}

function cleanup_r_patched() {
    rm -rf R-patched*
}

function compile_r_devel {
    (
	set -e
	if [ -e /opt/R/R-devel ]; then
	    >&2 echo /opt/R/R-devel already exists, exiting
	    exit 1
	fi
	cd R-devel
	if [ ! -e config.site.orig ]; then
	    mv config.site config.site.orig
	fi
	cp ../config.site .
	export LD_LIBRARY_PATH=/opt/csw/lib
	export PKG_CONFIG_PATH=/opt/csw/lib/pkgconfig
	export PATH=$PATH:/usr/ccs/bin
	export MAKE=/opt/csw/bin/gmake
	export TAR=/opt/csw/bin/gtar
	./configure -C --with-internal-tzcode --with-pcre1 \
		    --prefix=/opt/R/R-devel
	/opt/csw/bin/gmake
	/opt/csw/bin/gmake install
    )
}

function cleanup_r_devel() {
    rm -rf R-devel*
}

function cleanup() {
    cleanup_r_patched
    cleanup_r_devel
}

function main() {
    echo "== INSTALLING BUILD TOOLS ================="
    install_tools

    echo "== DOWNLOADING R-devel ===================="
    download_r_devel

    echo "== COMPILING R-devel ======================"
    compile_r_devel

    echo "== DOWNLOADING R-patched =================="
    download_r_patched

    echo "== COMPILING R-partched ==================="
    compile_r_patched
}

if [ "$sourced" = "0" ]; then
    set -e
    main
fi
