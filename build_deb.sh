#!/bin/bash
XENOMAI_VERSION=`/usr/xenomai/bin/xeno-config --version`
case $XENOMAI_VERSION in
	2.6*)
		XENOMAI_VERSION=2.6
	;;
	3.0*)
		XENOMAI_VERSION=3
	;;
esac

[ -z "$PKGNAME" ] && PKGNAME="libpd-xenomai-$XENOMAI_VERSION-dev"
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
VERSION="`git describe --tags | sed \"s/^[^0-9]*//\"`$DIRTY_HASH"
COMMIT=`git rev-parse HEAD`
BRANCH=`git rev-parse --abbrev-ref HEAD`
REMOTE=`git config --get remote.$BRANCH.url`

echo "libpd for arm and xenomai-$XENOMAI_VERSION. Has Pd 0.48" > description-pak
checkinstall --deldoc=yes --backup=no --pkgname="$PKGNAME" --pkgsource="$REMOTE $COMMIT $DIRTY_HASH" --provides="$PROVIDES" --conflicts="$CONFLICTS" --maintainer="`git config --get user.name` \<`git config --get user.email`\>" --pkgversion="$VERSION" -y make -f Makefile-Bela install
rm -rf description-pak
