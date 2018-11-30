#!/bin/sh

usage() {
cat << EOF
	Please init your environment first
	then run './compile.sh '
EOF
exit 1
}

[ -n "${SDKTARGETSYSROOT}" ] || usage

WORKDIR=$PWD
B=${WORKDIR}/openssh-7.1p2
D=${WORKDIR}/image
D_sshd=${WORKDIR}/sshd_install

sysconfdir=/etc
bindir=/usr/bin
datadir=/usr/share
localstatedir=/var
systemd_unitdir=/lib/systemd/
sbindir=/usr/sbin

#patch already done

# cd into build directory
cd ${B}

#configure
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
	--bindir=${bindir}           \
	--sbindir=/usr/sbin         \
	--libexecdir=/usr/lib/openssh           \
	--datadir=${datadir}        \
	--sysconfdir=${sysconfdir}           \
	--sharedstatedir=/com           \
	--localstatedir=${localstatedir}        \
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

#install
make -j4 DESTDIR=${D} install

echo "FRANK append install"
set -x
#install append
install -d ${D}${sysconfdir}/init.d
install -m 0755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/sshd
rm -f ${D}${bindir}/slogin ${D}${datadir}/Ssh.bin
rmdir ${D}${localstatedir}/run/sshd ${D}${localstatedir}/run ${D}${localstatedir}
install -d ${D}/${sysconfdir}/default/volatiles
install -m 644 ${WORKDIR}/volatiles.99_sshd ${D}/${sysconfdir}/default/volatiles/99_sshd
install -m 0755 ${B}/contrib/ssh-copy-id ${D}${bindir}
cat >>  ${D}/${sysconfdir}/default/ssh << EOF
SYSCONFDIR=/var/run/ssh
SSHD_OPTS='-f /etc/ssh/sshd_config_readonly'
EOF

# Create config files for read-only rootfs
install -d ${D}${sysconfdir}/ssh
install -m 644 ${D}${sysconfdir}/ssh/sshd_config ${D}${sysconfdir}/ssh/sshd_config_readonly
sed -i '/HostKey/d' ${D}${sysconfdir}/ssh/sshd_config_readonly
echo "HostKey /var/run/ssh/ssh_host_rsa_key" >> ${D}${sysconfdir}/ssh/sshd_config_readonly
echo "HostKey /var/run/ssh/ssh_host_dsa_key" >> ${D}${sysconfdir}/ssh/sshd_config_readonly
echo "HostKey /var/run/ssh/ssh_host_ecdsa_key" >> ${D}${sysconfdir}/ssh/sshd_config_readonly

install -d ${D}${systemd_unitdir}/system
install -c -m 0644 ${WORKDIR}/sshd.socket ${D}${systemd_unitdir}/system
install -c -m 0644 ${WORKDIR}/sshd@.service ${D}${systemd_unitdir}/system
install -c -m 0644 ${WORKDIR}/sshdgenkeys.service ${D}${systemd_unitdir}/system
sed -i -e 's,@BASE_BINDIR@,${base_bindir},g' \
	-e 's,@SBINDIR@,${sbindir},g' \
	-e 's,@BINDIR@,${bindir},g' \
	${D}${systemd_unitdir}/system/sshd.socket ${D}${systemd_unitdir}/system/*.service

# cd outof build directory
cd ${WORKDIR}

# collect minimal for sshd
install -d ${D_sshd}/${bindir}
install ${D}/${bindir}/ssh-keygen ${D_sshd}/${bindir}/ssh-keygen

install -d ${D_sshd}/${sbindir}
install ${D}/${sbindir}/sshd ${D_sshd}/${sbindir}/sshd

install -d ${D_sshd}/${sysconfdir}/ssh
install ${D}/${sysconfdir}/ssh/sshd_config ${D_sshd}/${sysconfdir}/ssh/sshd_config
install ${D}/${sysconfdir}/ssh/moduli ${D_sshd}/${sysconfdir}/ssh/moduli
install ${D}/${sysconfdir}/ssh/sshd_config_readonly ${D_sshd}/${sysconfdir}/ssh/sshd_config_readonly

install -d ${D_sshd}/${sysconfdir}/default/volatiles
install ${D}/${sysconfdir}/default/volatiles/99_sshd ${D_sshd}/${sysconfdir}/default/volatiles/99_sshd
install ${D}/${sysconfdir}/default/ssh ${D_sshd}/${sysconfdir}/default/ssh

install -d ${D_sshd}/${sysconfdir}/init.d
install ${D}/${sysconfdir}/init.d/sshd ${D_sshd}/${sysconfdir}/init.d/sshd
