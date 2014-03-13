#!/bin/bash
export VERSION=3.2.8
export DOWNLOADREV=
export PREVVERSION=3.2.6
export PACKAGEVERSION=3
export PREVPACKAGEVERSION=3
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta
[ -z "${MODULE}" ] && MODULE="mono"
export TAG_VERSION=$MODULE-$VERSION

. $(dirname "$0")/buildnewcommongit.sh

build
