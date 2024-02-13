#!/usr/bin/env bash

set -e

files=(
  "bin/install-wp-tests.sh"
  "bin/install-local-tests.sh"
  "bin/phpunit-test.sh"
  "bin/helpers.sh"
)

cd "$TEST_PROJECT_DIRECTORY"
test -d bin || (echo "❌ bin directory not found" >&2 && exit 1)

for file in "${files[@]}"; do 
  if [[ ! -f "$file" ]]; then
    echo "❌ $file not found" >&2
    exit 1
  fi
done
echo "✅ All bin files found"
