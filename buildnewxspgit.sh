#!/bin/bash
MODULE=xsp
VERSION=3.0.11
DOWNLOADREV=
PREVVERSION=3.0.11
PACKAGEVERSION=3
PREVPACKAGEVERSION=3
PPAUSERNAME=ermshiperete
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

. $(dirname "$0")/buildnewcommongit.sh

build
