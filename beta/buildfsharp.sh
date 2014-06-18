#!/bin/bash
# Build a new f-sharp version from the git repos
export VERSION=3.1.1.19
export PREVVERSION=
export TAG_VERSION=${VERSION}
export GITTAG=${TAG_VERSION}
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

WHERE=$(pwd)

# Prevent suffix adding to package names
export NOSUFFIX=1

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! -d fsharp ]; then
	echo "**************** Cloning f-sharp repo *******************"
	git clone https://github.com/fsharp/fsharp.git
fi

cd fsharp
echo "**************** Updating f-sharp repo *******************"
git reset --hard
git clean -dxf -e debian
git fetch origin
git checkout ${GITTAG}
git submodule update --init
cd $WHERE

if [ ! "${NOBUILD}" ]; then

	echo "**************** Processing f-sharp *******************"
	cd $WHERE
	if [ -f fsharp_${VERSION}.orig.tar.bz2 ] ; then
		tar xfj fsharp_${VERSION}.orig.tar.bz2
	else
		mkdir -p $WHERE/fsharp-${VERSION}
		cp -a $WHERE/fsharp/* $WHERE/fsharp-${VERSION}
		tar cfj fsharp_${VERSION}.orig.tar.bz2 --exclude=debian fsharp-${VERSION}
	fi
	if [ ! -d "fsharp-${VERSION}/debian" ]; then
		cp -r fsharp-${PREVVERSION}/debian fsharp-${VERSION}/
		cd fsharp-${VERSION}/debian
		dch --newversion ${VERSION}-1 --package fsharp --check-dirname-level 0 "New upstream release ${VERSION}"
		mv control /tmp/control
		sed 's/fsharp (>= [0-9.]*)/fsharp (>= '${VERSION}')/' < /tmp/control > control
	fi

	cd $WHERE/fsharp-${VERSION}
	# to force building/uploading of *.orig.tar.bz2 call: pdebuild --debbuildopts -sa
	pdebuild
	echo "***************** local dput ****************"
	cd /var/cache/pbuilder/$(lsb_release -c -s)-$(dpkg --print-architecture)/result/
	dput $FORCE local fsharp_${VERSION}*.changes
	cd $WHERE
fi

if [ ! "${NOUPLOAD}" ]; then
	echo "******************** Uploading changes **********************"
	for f in fsharp_${VERSION}-*source.changes; do
		debsign --no-re-sign $f
		dput ppa:ermshiperete/${REPO} $f
	done
fi
