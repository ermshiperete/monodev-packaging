#!/bin/bash
VERSION=1.1
DOWNLOADREV=
PREVVERSION=1.0
PACKAGEVERSION=4.0
PREVPACKAGEVERSION=4.0
PPAUSERNAME=ermshiperete
TAG_VERSION=mono-addins-$VERSION
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta
[ -z "${MODULE}" ] && MODULE="mono-addins"

. $(dirname "$0")/buildnewcommongit.sh

build
