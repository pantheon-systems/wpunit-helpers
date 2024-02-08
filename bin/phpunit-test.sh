#!/bin/bash

set -e

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

DIRNAME=$(dirname "$0")

echo "🤔 Installing WP Unit tests..."
bash "${DIRNAME}/install-wp-tests.sh" wordpress_test root root 127.0.0.1 latest

echo "📄 Copying wp-latest.json..."
cp /tmp/wp-latest.json "${DIRNAME}/../tests/wp-latest.json"

echo '------------------------------------------'
echo "🏃‍♂️ [Run 1]: Running PHPUnit on Single Site"
composer phpunit --ansi

echo "🧹 Removing files before testing WPMS..."
rm "${DIRNAME}/../tests/wp-latest.json"
rm -rf "$WP_TESTS_DIR" "$WP_CORE_DIR"

bash "${DIRNAME}/install-wp-tests.sh" wordpress_test root root 127.0.0.1 latest true
echo '------------------------------------------'
echo "🏃‍♂️ [Run 2]: Running PHPUnit on Multisite"
WP_MULTISITE=1 composer test --ansi

echo "🧹 Removing files before testing nightly WP..."

echo "🤔 Installing WP Unit tests with WP nightly version..."
bash "${DIRNAME}/install-wp-tests.sh" wordpress_test root root 127.0.0.1 nightly true
echo "📄 Copying wp-latest.json..."
cp /tmp/wp-latest.json "${DIRNAME}/../tests/wp-latest.json"

setup_wp_nightly

echo '------------------------------------------'
echo "🏃‍♂️ [Run 3]: Running PHPUnit on Single Site (Nightly WordPress)"
composer phpunit --ansi

echo '------------------------------------------'
echo "🏃‍♂️ [Run 4]: Running PHPUnit on Multisite (Nightly WordPress)"
WP_MULTISITE=1 composer phpunit --ansi

echo "Done! ✅"
