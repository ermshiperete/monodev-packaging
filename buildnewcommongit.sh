#!/bin/bash
if [ -z "$VERSION" ]; then
	echo "This file needs to be called from a wrapper!"
	exit 1
fi

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
	git checkout ${VERSION}
	git submodule update --init
	cd $WHERE

	if [ ! "${NOBUILD}" ]; then
		sudo -v
		echo "**************** Processing ${MODULE} *******************"
		if [ ! -f "${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2" ]; then
			mkdir -p $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			cp -a $WHERE/$MODULE/* $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			cd $WHERE
			echo "Creating source package"
			tar cfj ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ${MODULE}-${PACKAGEVERSION}-${VERSION}
		fi
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
	fi

	if [ ! "${NOUPLOAD}" ]; then
		echo "******************** Uploading changes **********************"
		debsign $(ls ${MODULE}-${PACKAGEVERSION}_${VERSION}*_source.changes | sort -n -r | head -1)
		dput ppa:$PPAUSERNAME/${REPO} $(ls ${MODULE}-${PACKAGEVERSION}_${VERSION}*_source.changes | sort -n -r | head -1)
	fi
}
