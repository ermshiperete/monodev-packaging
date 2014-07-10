#!/bin/bash
# Build a new fsharp-binding version from the git repos
export VERSION=3.2.31-1
export PREVVERSION=3.2.31
export PACKAGEVERSION=5
export PREVPACKAGEVERSION=5
export TAG_VERSION=${VERSION}
#export GITTAG=${TAG_VERSION}
export GITTAG=3.2.31
export PACKAGENAME=monodevelop-fsharpbinding
export GITREPONAME=fsharpbinding
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

WHERE=$(pwd)

# Prevent suffix adding to package names
export NOSUFFIX=1

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! -d ${GITREPONAME} ]; then
	echo "**************** Cloning ${GITREPONAME} repo *******************"
	git clone https://github.com/fsharp/${GITREPONAME}.git
fi

cd ${GITREPONAME}
echo "**************** Updating ${GITREPONAME} repo *******************"
git reset --hard
git clean -dxf -e debian
git fetch origin
git checkout ${GITTAG}
git submodule update --init
cd $WHERE

if [ ! "${NOBUILD}" ]; then

	cd $WHERE
	if [ -f ${PACKAGENAME}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ] ; then
		tar xfj ${PACKAGENAME}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2
	else
		mkdir -p $WHERE/${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}/lib
		cp -a $WHERE/${GITREPONAME}/monodevelop $WHERE/${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}
		cp -a $WHERE/${GITREPONAME}/lib $WHERE/${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}
		cp -a $WHERE/${GITREPONAME}/FSharp.CompilerBinding $WHERE/${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}
		tar cfj ${PACKAGENAME}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 --exclude=debian --exclude=.pc ${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}
	fi
	if [ ! -d "${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}/debian" ]; then
		cp -r ${PACKAGENAME}-${PREVPACKAGEVERSION}-${PREVVERSION}/debian ${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}/
		cd ${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}/debian
		dch --newversion ${VERSION}-1 --package ${PACKAGENAME}-${PACKAGEVERSION} --check-dirname-level 0 "New upstream release ${VERSION}"
		if [ "${PREVPACKAGEVERSION}" != "${PACKAGEVERSION}" ]
		then
			echo
			echo "Please adjust the patches, then exit the subshell"
			bash
			echo "Building ${PACKAGENAME}..."
		fi
	fi

	cd $WHERE/${PACKAGENAME}-${PACKAGEVERSION}-${VERSION}
	# to force building/uploading of *.orig.tar.bz2 call: pdebuild --debbuildopts -sa
	pdebuild $@
	echo "***************** local dput ****************"
	cd /var/cache/pbuilder/$(lsb_release -c -s)-$(dpkg --print-architecture)/result/
	dput $FORCE local ${PACKAGENAME}-${PACKAGEVERSION}_${VERSION}*.changes
	cd $WHERE
fi

if [ ! "${NOUPLOAD}" ]; then
	echo "******************** Uploading changes **********************"
	for f in ${PACKAGENAME}-${PACKAGEVERSION}_${VERSION}-*source.changes; do
		debsign --no-re-sign $f
		dput ppa:ermshiperete/${REPO} $f
	done
fi
