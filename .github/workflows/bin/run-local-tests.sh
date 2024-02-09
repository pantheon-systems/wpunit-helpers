#!/bin/bash

echo "Testing latest install..."
mkdir -p "$GITHUB_WORKSPACE"/local_tests
bash "$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --dbpass=root --tmpdir="$GITHUB_WORKSPACE"/local_tests

echo "Testing nightly install..."
bash "$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --version=nightly --skip-db=true --tmpdir="$GITHUB_WORKSPACE"/local_tests