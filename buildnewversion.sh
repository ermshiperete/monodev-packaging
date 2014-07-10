#!/bin/bash
export VERSION=5.0.1
export DOWNLOADREV=-0
export PREVVERSION=5.0
export PACKAGEVERSION=5
export PREVPACKAGEVERSION=5
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop

[ -z "${MODULES}" ] && MODULES="monodevelop monodevelop-debugger-gdb monodevelop-database"
WHERE=$(pwd)

# Prevent suffix adding to package names
export NOSUFFIX=1

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! "${NOBUILD}" ]; then

	for MODULE in $MODULES
	do
		echo "**************** Processing ${MODULE} *******************"
		if [ ! -d "${MODULE}-${PACKAGEVERSION}-${VERSION}/debian" ]; then
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
		else
			cd ${MODULE}-${PACKAGEVERSION}-${VERSION}
		fi
		# to force building/uploading of *.orig.tar.bz2 call: pdebuild --debbuildopts -sa
		pdebuild
		echo "***************** local dput ****************"
		cd /var/cache/pbuilder/$(lsb_release -c -s)-$(dpkg --print-architecture)/result/
		dput $FORCE local ${MODULE}-${PACKAGEVERSION}_${VERSION}*.changes
		cd $WHERE
	done
fi

if [ ! "${NOUPLOAD}" ]; then
	echo "******************** Uploading changes **********************"
	for MODULE in $MODULES
	do
		for f in ${MODULE}-${PACKAGEVERSION}_${VERSION}-*source.changes; do
			debsign --no-re-sign $f
			dput ppa:ermshiperete/${REPO} $f
		done
	done
fi
