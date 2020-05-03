#!/bin/bash

echo "Extracting Oracle Developer Studio 12.6"
cd /export/home/vagrant
bzip2 -dc OracleDeveloperStudio12.6-solaris-x86-pkg.tar.bz2 | tar xf -
cd OracleDeveloperStudio12.6-solaris-x86-pkg

# Install patches, these are crucial, for gcc as well (!)
echo "Installing ODS patches"
sudo ./install_patches.sh
# Not a typo, need to call twice to install all patches
sudo ./install_patches.sh

echo "Installing ODS"
sudo ./developerstudio.sh --non-interactive

cd /export/home/vagrant
rm -rf OracleDeveloperStudio12.6-solaris-x86-pkg*
