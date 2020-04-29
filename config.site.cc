# Copy this file in place of `config.site` and use somehing like
# ```
# ./configure -C --with-internal-tzcode --prefix=/opt/R/R-4.0.0
# make
# sudo make install
# ```
# to configure and install R

CC="/opt/developerstudio12.6/bin/cc -xc99"
CFLAGS='-O -xlibmieee -xlibmil -xtarget=native -xcache=generic -nofstore'
FC=/opt/developerstudio12.6/bin/f95
FFLAGS='-O -libmil -xtarget=native -xcache=generic -nofstore'
CXX=/opt/developerstudio12.6/bin/CC
CXXSTD="-std=c++11 -library=stdcpp,CrunG3"
CXXFLAGS="-O -xlibmil -xtarget=native -xcache=generic -nofstore"
CXX11STD=$CXXSTD
#CXX14STD="-std=c++14 -library=stdcpp,CrunG3"
FCLIBS_XTRA="-lfsu /opt/developerstudio12.6/lib/libfui.so.2"
FLIBS="-R/opt/developerstudio12.6/lib -lfsu /opt/developerstudio12.6/lib/compilers/libsunquad.a -lsunmath -lmtsk -lm"
SAFE_FFLAGS="-O -fstore"
R_LD_LIBRARY_PATH="/opt/developerstudio12.6/lib:/usr/local/lib:/opt/csw/lib"
