#!/usr/bin/env bash

set -ex
chmod +x "$GITHUB_WORKSPACE"/test_proj/bin/*.sh
echo "Testing latest install..."
mkdir -p "$GITHUB_WORKSPACE"/local_tests

if [ -f "$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh ]; then
  echo "install-local-tests.sh exists, proceeding"
else
  echo "install-local-tests.sh does not exist"
  exit 1
fi
ls -la "$GITHUB_WORKSPACE"/test_proj/bin

"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --dbpass=root --tmpdir="$GITHUB_WORKSPACE"/local_tests

echo "Testing nightly install..."
"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --version=nightly --skip-db=true --tmpdir="$GITHUB_WORKSPACE"/local_tests