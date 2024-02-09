#!/usr/bin/env bash

set -e

cd "$TEST_PROJECT_DIRECTORY"
test -d bin || (echo "❌ bin directory not found" >&2 && exit 1)
test -f bin/install-wp-tests.sh || (echo "❌ bin/install-wp-tests.sh not found" >&2 && exit 1)
test -f bin/install-local-tests.sh || (echo "❌ bin/install-local-tests.sh not found" >&2 && exit 1)
test -f bin/phpunit-test.sh || (echo "❌ bin/phpunit-test.sh not found" >&2 && exit 1)
test -f bin/helpers.sh || (echo "❌ bin/helpers.sh not found" >&2 && exit 1)
echo "✅ All bin files found"