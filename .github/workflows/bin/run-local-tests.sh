#!/bin/bash

set -ex

echo "Testing latest install..."
mkdir -p "$GITHUB_WORKSPACE"/local_tests
"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --dbpass=root --tmpdir="$GITHUB_WORKSPACE"/local_tests

echo "Testing nightly install..."
"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --version=nightly --skip-db=true --tmpdir="$GITHUB_WORKSPACE"/local_tests