#!/bin/sh

if [ -z ${SDKTARGETSYSROOT} ]; then
	echo "Please init your environment first"
	echo "then run './compile.sh'"
fi

WORKDIR=$PWD
B=${WORKDIR}/openssh-7.1p2

#patch already done

#configure
cd ${B}
export LD="${CC}"
install -m 0644 ${WORKDIR}/sshd_config ${B}/
install -m 0644 ${WORKDIR}/ssh_config ${B}/
if [ ! -e acinclude.m4 -a -e aclocal.m4 ]; then
	cp aclocal.m4 acinclude.m4
fi

./configure  \
	--build=x86_64-linux        \
	--host=arm-oe-linux-gnueabi         \
	--target=arm-oe-linux-gnueabi           \
	--prefix=/usr           \
	--exec_prefix=/usr          \
	--bindir=/usr/bin           \
	--sbindir=/usr/sbin         \
	--libexecdir=/usr/lib/openssh           \
	--datadir=/usr/share        \
	--sysconfdir=/etc           \
	--sharedstatedir=/com           \
	--localstatedir=/var        \
	--libdir=/usr/lib           \
	--includedir=/usr/include           \
	--oldincludedir=/usr/include        \
	--infodir=/usr/share/info           \
	--mandir=/usr/share/man         \
	--disable-silent-rules          \
	--disable-dependency-tracking           \
	--with-libtool-sysroot=${SDKTARGETSYSROOT}	\
	LOGIN_PROGRAM=/bin/login                 \
	--without-pam                 \
	--without-zlib-version-check                 \
	--with-privsep-path=/var/run/sshd                 \
	--sysconfdir=/etc/ssh                 \
	--with-xauth=/usr/bin/xauth                 \
	--disable-strip                   \
	--without-audit \
	--without-selinux

#compile
make -j4
make -j4 DESTDIR=${WORKDIR}/image install
cd ${WORKDIR}

#install
