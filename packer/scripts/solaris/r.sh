#! /bin/bash

# Need this for R-hub's SSL certs
pkgutil -y -i cacertificates

echo "" >> /opt/csw/etc/pkgutil.conf
echo "mirror=http://mirror.opencsw.org/opencsw/testing" \
     >> /opt/csw/etc/pkgutil.conf
echo "# R-hub's own registry for updated R versions" \
     >> /opt/csw/etc/pkgutil.conf
echo "mirror=https://files.r-hub.io/opencsw" \
     >> /opt/csw/etc/pkgutil.conf

pkgutil -U
pkgutil -y -i r_base
