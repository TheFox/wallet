#!/usr/bin/env bash

SCRIPT_BASEDIR=$(dirname "$0")


set -e
which docker &> /dev/null || { echo 'ERROR: docker not found in PATH'; exit 1; }

cd "${SCRIPT_BASEDIR}/.."
. ./.env

set -x
docker run \
	--tty \
	--interactive \
	--name ${IMAGE_NAME_SHORT} \
	--hostname ${IMAGE_NAME_SHORT} \
	--volume "$PWD":/app \
	${IMAGE_NAME}
