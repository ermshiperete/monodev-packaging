#!/bin/bash
if [ -z "$VERSION" ]; then
	echo "This file needs to be called from a wrapper!"
	exit 1
fi

[ -z "${PACKAGE_NAME}" ] && PACKAGE_NAME=$MODULE
[ -z "${TAG_VERSION}" ] && TAG_VERSION=$VERSION
[ -z "${PPAUSERNAME}" ] && PPAUSERNAME=ermshiperete

# Prevent suffix adding to package names
export NOSUFFIX=1

set -e

build()
{
	WHERE=$(pwd)

	set -e

	# force dput pushing to launchpad
	[ "$1" = "--force" ] && FORCE=-f

	if [ ! -d $MODULE ]; then
		echo "**************** Cloning $MODULE repo *******************"
		git clone https://github.com/mono/$MODULE.git
	fi

	echo "**************** Updating $MODULE repo *******************"
	cd $MODULE
	git reset --hard
	git clean -dxf -e debian
	git fetch origin
	git checkout ${TAG_VERSION}
	git submodule update --init
	cd $WHERE

	if [ ! "${NOBUILD}" ]; then
		sudo -v
		echo "**************** Processing ${MODULE} *******************"
		if [ ! -f "${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2" ]; then
			mkdir -p $WHERE/${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}
			cp -a $WHERE/$MODULE/* $WHERE/${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}
			cd $WHERE
			echo "Creating source package"
			tar cfj ${PACKAGE_NAME}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}
		fi
		if [ ! -d "${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}/debian" ]; then
			echo "Creating debian directory"
			cp -r ${PACKAGE_NAME}-${PREVPACKAGEVERSION}-${PREVVERSION}/debian ${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}/
			cd ${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}/debian
			dch --newversion ${VERSION}-1 --package ${PACKAGE_NAME}-${PACKAGEVERSION} --check-dirname-level 0 "New upstream release ${VERSION}"
			mv control /tmp/control
			if [ "${PREVPACKAGEVERSION}" != "${PACKAGEVERSION}" ]
			then
				sed -e 's/\(monodevelop.*-\)'${PREVPACKAGEVERSION}'/\1'${PACKAGEVERSION}'/g' -e 's/\(Replaces\: monodevelop.*-\)[0-9.]*/\1'${PREVPACKAGEVERSION}'/' < /tmp/control > /tmp/control2
				mv /tmp/control2 /tmp/control
				echo
				echo "Please adjust the patches, then exit the subshell"
				bash
			fi
			sed 's/${PACKAGE_NAME}-'${PACKAGEVERSION}' (>= [0-9.]*)/${PACKAGE_NAME}-'${PACKAGEVERSION}' (>= '${VERSION}')/' < /tmp/control > control
		fi
		echo "Starting build"
		cd $WHERE/${PACKAGE_NAME}-${PACKAGEVERSION}-${VERSION}
		# to force building/uploading of *.orig.tar.bz2 call: pdebuild --debbuildopts -sa
		AUTO_DEBSIGN=no pdebuild
		cd /var/cache/pbuilder/$(lsb_release -c -s)-$(dpkg --print-architecture)/result/
		echo "Signing changes file"
		debsign -k42CDA9D8 ${PACKAGE_NAME}-${PACKAGEVERSION}_${VERSION}*.changes
		dput $FORCE local ${PACKAGE_NAME}-${PACKAGEVERSION}_${VERSION}*.changes
		cd $WHERE
	fi

	if [ ! "${NOUPLOAD}" ]; then
		echo "******************** Uploading changes **********************"
		debsign $(ls ${PACKAGE_NAME}-${PACKAGEVERSION}_${VERSION}*_source.changes | sort -n -r | head -1)
		dput ppa:$PPAUSERNAME/${REPO} $(ls ${PACKAGE_NAME}-${PACKAGEVERSION}_${VERSION}*_source.changes | sort -n -r | head -1)
	fi
}
