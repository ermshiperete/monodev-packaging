#!/bin/bash
# Build a new MonoDevelop version from the git repos
export VERSION=4.3.0
export PREVVERSION=4.2.2
export PACKAGEVERSION=4.0
export PREVPACKAGEVERSION=4.0
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

[ -z "${MODULES}" ] && MODULES="monodevelop monodevelop-debugger-gdb monodevelop-database"
WHERE=$(pwd)

set -e

# force dput pushing to launchpad
[ "$1" = "--force" ] && FORCE=-f

if [ ! -d monodevelop ]; then
	echo "**************** Cloning MonoDevelop repo *******************"
	git clone https://github.com/mono/monodevelop.git
fi

cd monodevelop
echo "**************** Updating MonoDevelop repo *******************"
git reset --hard
git clean -dxf -e debian
git fetch origin
git checkout monodevelop-${VERSION}
git submodule update --init
cd $WHERE

if [ ! "${NOBUILD}" ]; then

	for MODULE in $MODULES
	do
		echo "**************** Processing ${MODULE} *******************"
		case "$MODULE" in
		"monodevelop")
			SUBDIR=main
			;;
		"monodevelop-debugger-gdb")
			SUBDIR=extras/MonoDevelop.Debugger.Gdb
			;;
		"monodevelop-database")
			SUBDIR=extras/MonoDevelop.Database
			;;
		"monodevelop-aspnetedit")
			SUBDIR=extras/AspNetEdit
			;;
		"monodevelop-boo")
			SUBDIR=extras/BooBinding
			;;
		"monodevelop-java")
			SUBDIR=extras/JavaBinding
			;;
		"monodevelop-lua")
			SUBDIR=extras/LuaBinding
			;;
		"monodevelop-addinauthoring")
			SUBDIR=extras/MonoDevelop.AddinAuthoring
			;;
		"monodevelop-codeanalysis")
			SUBDIR=extras/MonoDevelop.CodeAnalysis
			;;
		"monodevelop-debugger-mdb")
			SUBDIR=extras/MonoDevelop.Debugger.Mdb
			;;
		"monodevelop-meego")
			SUBDIR=extras/MonoDevelop.MeeGo
			;;
		"monodevelop-profiling")
			SUBDIR=extras/MonoDevelop.Profiling
			;;
		"monodevelop-nemerle")
			SUBDIR=extras/NemerleBinding
			;;
		"monodevelop-oosamples")
			SUBDIR=extras/OpenOfficeSamples
			;;
		"monodevelop-py")
			SUBDIR=extras/PyBinding
			;;
		"monodevelop-python")
			SUBDIR=extras/PythonBinding
			;;
		"monodevelop-vala")
			SUBDIR=extras/ValaBinding
			;;
		esac
		cp -a $WHERE/monodevelop/$SUBDIR $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
		cd $WHERE
		tar cfj ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ${MODULE}-${PACKAGEVERSION}-${VERSION}
		if [ ! -d "${MODULE}-${PACKAGEVERSION}-${VERSION}/debian" ]; then
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
		fi
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
