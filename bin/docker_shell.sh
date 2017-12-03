#!/usr/bin/env bash

SCRIPT_BASEDIR=$(dirname "$0")


set -e
which docker &> /dev/null || { echo 'ERROR: docker not found in PATH'; exit 1; }

cd "${SCRIPT_BASEDIR}/.."
. ./.env

docker exec --interactive --tty ${IMAGE_NAME_SHORT} bash
