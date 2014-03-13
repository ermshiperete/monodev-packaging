#!/bin/bash
MODULE=mod_mono
PACKAGE_NAME=libapache2-mod-mono
VERSION=2.10
DOWNLOADREV=
PREVVERSION=2.10
PACKAGEVERSION=3
PREVPACKAGEVERSION=3
PPAUSERNAME=ermshiperete
# REPO specifies the launchpad project where the package should end up. This should probably
# be monodevelop or monodevelop-beta
[ -z "${REPO}" ] && REPO=monodevelop-beta

. $(dirname "$0")/buildnewcommongit.sh

build
