#!/usr/bin/env bash

# Run all tests.

SCRIPT_BASEDIR=$(dirname "$0")
RUBYOPT=-w
TZ=Europe/Vienna


set -e
which bundler &> /dev/null || { echo 'ERROR: bundler not found in PATH'; exit 1; }

cd "${SCRIPT_BASEDIR}/.."

mkdir -p tmp
bundler exec ./test/suite_all.rb -v
