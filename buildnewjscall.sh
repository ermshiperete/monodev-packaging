#!/bin/bash
MODULE=jscall-sharp
VERSION=0.0.1
DOWNLOADREV=
PREVVERSION=0.0.0
PACKAGEVERSION=0
PREVPACKAGEVERSION=0
PPAUSERNAME=ermshiperete
TAG_VERSION=master
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

. $(dirname "$0")/buildnewcommongit.sh

build
