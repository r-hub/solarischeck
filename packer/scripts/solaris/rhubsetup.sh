#! /bin/bash

# Refine PATH and other env vars

echo "Refining the default bash profile"
echo "" >> /etc/profile
echo "PATH=/opt/csw/sbin:/opt/csw/bin:/bin:/sbin:/usr/sbin:/usr/bin:/usr/sfw/bin:/usr/sfw/sbin:/usr/ccs/bin" \
     >> /etc/profile
echo "MANPATH=/opt/csw/share/man:/usr/sfw/share/man:/usr/share/man" \
     >> /etc/profile
echo "PKG_CONFIG_PATH=/opt/csw/lib/pkgconfig" \
     >> /etc/profile
echo "TERM=vt100" \
     >> /etc/profile
echo "PAGER=less" \
     >> /etc/profile
echo "export PATH MANPATH PKG_CONFIG_PATH TERM PAGER" \
     >> /etc/profile

# Create rhub user

echo "Creating rhub user"
groupadd rhub
useradd -m -d /export/home/rhub -s /bin/bash -g rhub rhub

PASSWD=`perl -e 'print crypt($ARGV[0], substr(rand(data),2));' solaris`
cat /etc/shadow | sed -e 's#^rhub:UP:#rhub:'${PASSWD}'#g'  > /tmp/shadow.$$
cat /tmp/shadow.$$ > /etc/shadow

test -f /etc/sudoers &&
    grep -v "rhub" "/etc/sudoers" 1>/dev/null 2>&1 &&
    echo "rhub ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up a reasonable R profile

echo "Setting up .Rprofile"
cat >/export/home/rhub/.Rprofile <<EOF
options(repos = c(CRAN = "http://cloud.r-project.org"))
EOF

chown rhub::rhub /export/home/rhub/.Rprofile

# Install the ODS version of R

echo "Installing the ODS version of R"
mkdir -p /opt/R
cd /opt/R
wget https://files.r-hub.io/solaris/R-release.tar.gz
/opt/csw/bin/gtar xzf R-release.tar.gz
rm R-release.tar.gz

# Create icons for the terminal and R

echo "Creating desktop icons"
mv /export/home/vagrant/Rlogo.png /opt/R

RVERSION=`R -q --slave -e 'cat(as.character(getRversion()))'`
ODSRVERSION=`/opt/R/R-*/bin/R -q --slave -e 'cat(as.character(getRversion()))'`
mkdir -p /export/home/rhub/Desktop

cat >/export/home/rhub/Desktop/Terminal <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Exec=gnome-terminal
TryExec=
Icon=/usr/share/pixmaps/gnome-terminal.png
X-GNOME-DocPath=
Terminal=false
Name=Terminal
GenericName=
Comment=
EOF

cat >/export/home/rhub/Desktop/R-32.desktop <<EOF
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=R ${RVERSION}
Type=Application
Exec=/opt/csw/bin/R
TryExec=
Icon=/opt/R/Rlogo.png
X-GNOME-DocPath=
Terminal=true
GenericName=
Comment=
EOF

cat >/export/home/rhub/Desktop/R-64.desktop <<EOF
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=R ${RVERSION} (64 bit)
Type=Application
Exec=/opt/csw/bin/amd64/R
TryExec=
Icon=/opt/R/Rlogo.png
X-GNOME-DocPath=
Terminal=true
GenericName=
Comment=
EOF

cat >/export/home/rhub/Desktop/R-ODS.desktop <<EOF
[Desktop Entry]
Version=1.0
Encoding=UTF-8
Name=R ${ODSRVERSION} (ODS)
Type=Application
Exec=/opt/R/R-${ODSRVERSION}/bin/R
TryExec=
Icon=/opt/R/Rlogo.png
X-GNOME-DocPath=
Terminal=true
GenericName=
Comment=
EOF

chown -R rhub:rhub /export/home/rhub/Desktop
