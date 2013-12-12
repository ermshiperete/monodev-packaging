#!/bin/bash
export VERSION=3.2.5
export DOWNLOADREV=
export PREVVERSION=3.2.4
export PACKAGEVERSION=3
export PREVPACKAGEVERSION=3
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta
[ -z "${MODULES}" ] && MODULES="mono"
WHERE=$(pwd)

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! -d mono ]; then
	echo "**************** Cloning Mono repo *******************"
	git clone https://github.com/mono/mono.git
fi

cd mono
echo "**************** Updating Mono repo *******************"
git reset --hard
git clean -dxf -e debian
git fetch origin
git checkout mono-${VERSION}
git submodule update --init
cd $WHERE

if [ ! "${NOBUILD}" ]; then

	for MODULE in $MODULES
	do
		sudo -v
		echo "**************** Processing ${MODULE} *******************"
		mkdir -p $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
		cp -a $WHERE/mono/* $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
		cd $WHERE
		echo "Creating source package"
		tar cfj ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ${MODULE}-${PACKAGEVERSION}-${VERSION}
		if [ ! -d "${MODULE}-${PACKAGEVERSION}-${VERSION}/debian" ]; then
			echo "Creating debian directory"
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
			sed 's/${MODULE}-'${PACKAGEVERSION}' (>= [0-9.]*)/${MODULE}-'${PACKAGEVERSION}' (>= '${VERSION}')/' < /tmp/control > control
		fi
		echo "Starting build"
		cd $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
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
		debsign ${MODULE}-${PACKAGEVERSION}_${VERSION}*source.changes
		dput ppa:ermshiperete/${REPO} ${MODULE}-${PACKAGEVERSION}_${VERSION}*source.changes
	done
fi
