#!/bin/bash
export VERSION=4.2.2
export DOWNLOADREV=-2
export PREVVERSION=4.2
export PACKAGEVERSION=4.0
export PREVPACKAGEVERSION=4.0
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop

[ -z "${MODULES}" ] && MODULES="monodevelop monodevelop-debugger-gdb monodevelop-database"
WHERE=$(pwd)

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! "${NOBUILD}" ]; then

	for MODULE in $MODULES
	do
		echo "**************** Processing ${MODULE} *******************"
		wget --continue http://download.mono-project.com/sources/${MODULE}/${MODULE}-${VERSION}${DOWNLOADREV}.tar.bz2
		tar xfj ${MODULE}-${VERSION}${DOWNLOADREV}.tar.bz2
		mv ${MODULE}-${VERSION}${DOWNLOADREV}.tar.bz2 ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2
		mv ${MODULE}-${VERSION} ${MODULE}-${PACKAGEVERSION}-${VERSION}
		cp -r ${MODULE}-${PREVPACKAGEVERSION}-${PREVVERSION}/debian ${MODULE}-${PACKAGEVERSION}-${VERSION}/
		cd ${MODULE}-${PACKAGEVERSION}-${VERSION}/debian
		dch --newversion ${VERSION}-1 --package ${MODULE}-${PACKAGEVERSION} --check-dirname-level 0 "New upstream release ${VERSION}"
		mv control /tmp/control
		if [ "${PREVPACKAGEVERSION}" != "${PACKAGEVERSION}" ]
		then
			sed -e 's/\(monodevelop.*-\)'${PREVPACKAGEVERSION}'/\1'${PACKAGEVERSION}'/g' -e 's/\(Replaces\: monodevelop.*-\)[0-9.]*/\1'${PREVPACKAGEVERSION}'/' < /tmp/control > /tmp/control2
			mv /tmp/control2 /tmp/control
			echo
			echo "Please adjust the patches, then exit the subshell"
			bash
		fi
		sed 's/monodevelop-'${PACKAGEVERSION}' (>= [0-9.]*)/monodevelop-'${PACKAGEVERSION}' (>= '${VERSION}')/' < /tmp/control > control
		cd ..
		# to force building/uploading of *.orig.tar.bz2 call: pdebuild --debbuildopts -sa
		pdebuild
		cd /var/cache/pbuilder/$(lsb_release -c -s)-$(dpkg --print-architecture)/result/
		dput $FORCE local ${MODULE}-${PACKAGEVERSION}_${VERSION}*.changes
		cd $WHERE
	done
fi

if [ ! "${NOUPLOAD}" ]; then
	echo "******************** Uploading changes **********************"
	for MODULE in $MODULES
	do
		debsign ${MODULE}-${PACKAGEVERSION}_${VERSION}-*source.changes
		dput ppa:ermshiperete/${REPO} ${MODULE}-${PACKAGEVERSION}_${VERSION}-*source.changes
	done
fi
