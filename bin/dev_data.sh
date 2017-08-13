#!/usr/bin/env bash

# Generate dev data.

SCRIPT_BASEDIR=$(dirname "$0")


set -e
cd "${SCRIPT_BASEDIR}/.."

cwd="tmp/dev"
mkdir -p tmp/test_wallet

bundler exec bin/wallet -w tmp/test_wallet add -t 'test1' -d 2016-2-3 -e 10
bundler exec bin/wallet -w tmp/test_wallet add -t 'test2' -d 2016-2-1 -e 10 -r 20
bundler exec bin/wallet -w tmp/test_wallet add -t 'test3' -d 2016-1-1 -r 20
bundler exec bin/wallet -w tmp/test_wallet add -t 'test4' -d 2015-1-1 -r 20
bundler exec bin/wallet -w tmp/test_wallet add -t 'test5' -d 2014-1-1 -r 20
