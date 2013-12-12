#!/bin/bash
VERSION=2.12.22
DOWNLOADREV=
PREVVERSION=2.12.21
PACKAGEVERSION=4.0
PREVPACKAGEVERSION=4.0
PPAUSERNAME=ermshiperete
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta
[ -z "${MODULE}" ] && MODULE="gtk-sharp"

. $(dirname "$0")/buildnewcommongit.sh

build
