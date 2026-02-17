#!/bin/bash
set -e
set -x
[ -z "$XENOMAI_VERSION" ] && XENOMAI_VERSION=`/usr/xenomai/bin/xeno-config --version`
case $XENOMAI_VERSION in
	2.6*)
		XENOMAI_VERSION=2.6
	;;
	3.0*)
		XENOMAI_VERSION=3
	;;
esac

[ -z "$PKGNAME" ] && PKGNAME="libpd-bela-dev"
PROVIDES="libpd-dev"
CONFLICTS=

DIRTY_HASH=`git diff --quiet && git diff --cached --quiet || echo "-dirty"`
TAG=`git describe --tags`
if [ "$TAG" = "`git describe --tags --abbrev=0`" ]
then
	echo "We are on a tag: $TAG $DIRTY_HASH"
fi
VERSION=""
#ensure VERSION starts with a number, or checkinstall will complain
PD_VERSION="$(cd pure-data && git describe --tags HEAD)"
VERSION="`git describe --tags | sed \"s/^[^0-9]*//\"`$DIRTY_HASH-Pd-$PD_VERSION"
COMMIT=`git rev-parse HEAD`
BRANCH=`git rev-parse --abbrev-ref HEAD`
REMOTE=$(git config --get remote.$BRANCH.url || true)

echo "libpd for arm and xenomai-$XENOMAI_VERSION. Has Pd $PD_VERSION" > description-pak

mkdir -p /usr/local/include/libpd
checkinstall --type=debian --deldoc=yes --backup=no --pkgname="$PKGNAME" --pkgsource="$REMOTE $COMMIT $DIRTY_HASH" --provides="$PROVIDES" --conflicts="$CONFLICTS" --maintainer="`git config --get user.name` \<`git config --get user.email`\>" --pkgversion="$VERSION" -y make -f Makefile-Bela install-full
rm -rf description-pak

# rebuild package to add postinst and remove stale files
set -e

old=$PWD
deb="$old/${PKGNAME}_${VERSION}-1_arm64.deb"
rm -rf /tmp/libpd
mkdir /tmp/libpd
cd /tmp/libpd
ar xf $deb
unxz control.tar.xz
unxz data.tar.xz
mkdir -p rootfs/DEBIAN
cd rootfs/DEBIAN
tar xvf ../../control.tar
echo -e "#!/bin/bash

ldconfig" > postinst
chmod +x postinst
cd ..
tar xvf ../data.tar
cd ..
rm -rf rootfs/usr/share
rm -rf rootfs/root
dpkg-deb -Z xz --root-owner-group --build rootfs/ $deb
echo $deb
