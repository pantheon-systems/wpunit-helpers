#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source "$GITHUB_WORKSPACE"/bin/helpers.sh

chmod +x "$GITHUB_WORKSPACE"/test_proj/bin/*.sh
echo "Testing latest install..."
mkdir -p "$GITHUB_WORKSPACE"/local_tests

if [ ! -f "$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh ]; then
  echo "install-local-tests.sh does not exist"
  exit 1
fi

"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --dbpass="$DB_PASS" --tmpdir="$GITHUB_WORKSPACE"/local_tests

echo "Testing nightly install..."
"$GITHUB_WORKSPACE"/test_proj/bin/install-local-tests.sh --version=nightly --skip-db=true --tmpdir="$GITHUB_WORKSPACE"/local_tests

cleanup "$GITHUB_WORKSPACE/local_tests"
mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"

echo "Done! ✅"