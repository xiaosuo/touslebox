#!/bin/bash
#
# Build a minimal Debian raw disk image. 
#
# References: http://www.debian.org/releases/stable/i386/apds03.html.en
#
# Copyright (C) 2012-  Changli Gao <xiaosuo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

if [ $EUID -ne 0 ]; then
	echo "You must be root to run this script"
	exit 1
fi
# check the necessary tools
if ! which debootstrap &>/dev/null; then
	echo "debootstrap isn't found"
	exit 1
fi
if ! which grub-install &>/dev/null; then
	echo "grub isn't found"
	exit 1
fi

if [ $# -eq 1 ]; then
	source $1
elif [ $# -gt 1 ]; then
	echo "Usage: $0 [CONFIG_FILE]"
	exit 1
fi
DIST=${DIST:-debian}
SUITE=${SUITE:-stable}
IMAGE=${IMAGE:-${DIST}-$SUITE.raw}
test -e $IMAGE || dd if=/dev/zero of=$IMAGE bs=512 count=$((500*1024*1024/512))
IMAGE_SIZE=$(stat -c %s $IMAGE)
if [ $IMAGE_SIZE -lt $((500*1024*1024)) ]; then
	echo "$IMAGE is too small, and it should be 500M at least"
	exit 1
fi
ARCH=${ARCH:-i386}
MIRROR=${MIRROR:-http://mirrors.163.com/$DIST}
HOSTNAME=${HOSTNAME:-$DIST}
TIMEZONE=${TIMEZONE:-Etc/UTC}
NAMESERVER=${NAMESERVER:-8.8.8.8}

STEP=0

cleanup()
{
	echo -n "Cleanup with step: $STEP..."
	test $STEP -ge 5 && umount $TARGET/proc
	test $STEP -ge 4 && umount $TARGET
	test $STEP -ge 3 && rmdir $TARGET
	test $STEP -ge 2 && losetup -d /dev/loop1
	test $STEP -ge 1 && losetup -d /dev/loop0
	echo "done"
}

trap 'cleanup' EXIT

echo -n "Creating the partition table..."
losetup /dev/loop0 $IMAGE
STEP=1
# reserve 64 sectors for grub
sfdisk -uS -S 1 -H 1 -C $((IMAGE_SIZE/512)) /dev/loop0 <<EOF
64,$((IMAGE_SIZE/512-64)),L,*
EOF
echo "done"

echo -n "Making file systems..."
losetup /dev/loop1 $IMAGE -o $((64*512)) --sizelimit \
	$((IMAGE_SIZE-64*512))
STEP=2
mke2fs -j /dev/loop1
UUID=$(blkid /dev/loop1 | sed 's/.*UUID="\([0-9a-f-]\+\)".*/\1/g')
echo "done"

echo -n "Mounting file systems..."
TARGET=$(mktemp -d)
STEP=3
mount /dev/loop1 $TARGET
STEP=4
echo "done"

echo -n "Installing the base system..."
if [ -n "$VARIANT" ]; then
	debootstrap --variant=$VARIANT --arch $ARCH $SUITE $TARGET $MIRROR
else
	debootstrap --arch $ARCH $SUITE $TARGET $MIRROR
fi
echo "done"

echo -n "Configuring the base system..."
cat > $TARGET/etc/fstab <<EOF
UUID=$UUID / ext3 defaults 0 1
proc /proc proc defaults 0 0
EOF
mkdir $TARGET/media/cdrom0
ln -s cdrom0 $TARGET/media/cdrom
ln -s media/cdrom $TARGET/cdrom
mount -t proc proc $TARGET/proc
STEP=5
echo $TIMEZONE > $TARGET/etc/timezone
cp $TARGET/usr/share/zoneinfo/$TIMEZONE $TARGET/etc/localtime
cat > $TARGET/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback
EOF
echo "nameserver $NAMESERVER" > $TARGET/etc/resolv.conf
echo $HOSTNAME > $TARGET/etc/hostname
cat > $TARGET/etc/hosts <<EOF
127.0.0.1 localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF
cat >> $TARGET/etc/apt/sources.list <<EOF
deb http://security.debian.org/ squeeze/updates main
EOF
# erase the password of root
sed -i '/root/s/\*//g' $TARGET/etc/shadow
echo "done"

chroot_do()
{
	chroot $TARGET /bin/bash -c "$1"
}

echo -n "Installing the kernel..."
case $DIST in
debian)
	case $ARCH in
	i386)
		KERNEL_ARCH=686
		;;
	amd64)
		KERNEL_ARCH=amd64
		;;
	*)
		echo "Unsupported architecture: $ARCH"
		;;
	esac
	LINUX=linux-image-$KERNEL_ARCH
	;;
ubuntu)
	LINUX=linux-image
	# preconfigure grub-pc pulled in by linux-image
	cat >>$TARGET/var/cache/debconf/config.dat <<-EOF
	Name: grub-pc/install_devices
	Template: grub-pc/install_devices
	Value: 
	Owners: grub-pc
	Flags: seen

	Name: grub-pc/install_devices_empty
	Template: grub-pc/install_devices_empty
	Value: true
	Owners: grub-pc
	Flags: seen

	EOF
	;;
*)
	echo "Unsupported distribution: $DIST"
	;;
esac
chroot_do "apt-get -y --force-yes install $LINUX"
echo "done"

echo -n "Installing the boot loader..."
grub-install --modules=part_msdos --root-directory=$TARGET /dev/loop0
cat >$TARGET/boot/grub/grub.cfg <<EOF
set default=0
set timeout=5

insmod ext2

search --fs-uuid --set $UUID

menuentry "$DIST" {
	linux /vmlinuz root=UUID=$UUID
	initrd /initrd.img
}
EOF
echo "done"

echo -n "Cleaning up..."
chroot_do 'apt-get clean'
# TODO: remove doc, man, locales and ....
echo "done"

cat <<EOF
$IMAGE is ready, and you can test it with qemu now:
    qemu-system-i386 -hda $IMAGE -curses
You can also convert it to a VMDK disk image with qemu-img:
    qemu-img convert -f raw -O vmdk $IMAGE ${IMAGE%.*}.vmdk
EOF
