#!/bin/bash
# Build a new MonoDevelop version from the git repos
export VERSION=5.4.0.194
export PREVVERSION=5.4.0.178
export PACKAGEVERSION=5
export PREVPACKAGEVERSION=5
export TAG_VERSION=${VERSION}
export GITTAG=monodevelop-${TAG_VERSION}
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

[ -z "${MODULES}" ] && MODULES="monodevelop monodevelop-database"
WHERE=$(pwd)

# Prevent suffix adding to package names
export NOSUFFIX=1

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
git checkout ${GITTAG}
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
		#"monodevelop-debugger-gdb")
		#	SUBDIR=extras/MonoDevelop.Debugger.Gdb
		#	;;
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
		cd $WHERE
		if [ -f ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 ] ; then
			tar xfj ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2
		else
			mkdir -p $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			cp -a $WHERE/monodevelop/$SUBDIR/* $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			cp -a $WHERE/monodevelop/version.config $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			cp -a $WHERE/monodevelop/scripts $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			tar cfj ${MODULE}-${PACKAGEVERSION}_${VERSION}.orig.tar.bz2 --exclude=debian ${MODULE}-${PACKAGEVERSION}-${VERSION}
		fi
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
				echo "Building ${MODULE}..."
			fi
			sed 's/monodevelop-'${PACKAGEVERSION}' (>= [0-9.]*)/monodevelop-'${PACKAGEVERSION}' (>= '${VERSION}')/' < /tmp/control > control
		fi
		if [ "$MODULE" = "monodevelop" ]; then
			# Update version information
			echo "Update version information"
			cd $WHERE/monodevelop/main
			mkdir -p build/bin
			../scripts/configure.sh gen-buildinfo "./build/bin"
			cd $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
			quilt push -a || true
			if [ "$(quilt top)" != "buildinfo.patch" ]; then
				quilt new buildinfo.patch
				quilt add build/bin/buildinfo
			fi
			cp -a $WHERE/monodevelop/main/build/bin build/
			quilt refresh
			quilt pop -a > /dev/null

			# Update NuGet packages
			echo "Update nuget packages"
			cd $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}/
			quilt push -a
			quilt pop 2
			if [ "$(quilt top)" = "nuget-packages.patch" ]; then
				quilt pop 1
			fi
			TMPNUGETBASE=/tmp/${MODULE}
			TMPNUGETDIR=$TMPNUGETBASE/${MODULE}-${PACKAGEVERSION}-${VERSION}/
			TMPNUGETORIG=$TMPNUGETBASE/orig
			mkdir -p $TMPNUGETBASE
			[ -d $TMPNUGETORIG ] || cp -a $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}/ $TMPNUGETORIG
			rm -rf $TMPNUGETDIR || true
			cp -a $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}/ $TMPNUGETDIR
			echo "Restoring packages in src/addins/AspNet/"
			pushd $TMPNUGETDIR/src/addins/AspNet/
			mono $TMPNUGETDIR/external/nuget-binary/NuGet.exe restore -SolutionDirectory $TMPNUGETDIR
			echo "Restoring packages in src/addins/NUnit/NUnitRunner/"
			cd $TMPNUGETDIR/src/addins/NUnit/NUnitRunner/
			mono $TMPNUGETDIR/external/nuget-binary/NuGet.exe restore -SolutionDirectory $TMPNUGETDIR
			popd
#
#			NUGETPACKS=$(find . -name packages.config)
#			for p in $NUGETPACKS; do
#				PACKDIR=$(dirname $p)
#				if grep -q -i nuget $PACKDIR/*; then
#					echo "Restoring packages in $PACKDIR"
#					pushd $PACKDIR
#					mono $TMPNUGETDIR/external/nuget-binary/NuGet.exe restore -SolutionDirectory $TMPNUGETDIR || true
#					popd
#				fi
#			done
			pushd $TMPNUGETBASE
			diff -Naur orig/packages ${MODULE}-${PACKAGEVERSION}-${VERSION}/packages > /tmp/nuget-packages.patch || true
			popd
			quilt import -d n -f /tmp/nuget-packages.patch
			quilt pop -a
		fi

		cd $WHERE/${MODULE}-${PACKAGEVERSION}-${VERSION}
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
