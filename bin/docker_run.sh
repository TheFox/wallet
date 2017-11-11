#!/usr/bin/env bash

SCRIPT_BASEDIR=$(dirname "$0")


set -e
which docker &> /dev/null || { echo 'ERROR: docker not found in PATH'; exit 1; }

cd "${SCRIPT_BASEDIR}/.."

set -x
docker run \
	--tty \
	--interactive \
	--name wallet \
	--volume "$PWD":/usr/local/src \
	thefox/wallet:latest
