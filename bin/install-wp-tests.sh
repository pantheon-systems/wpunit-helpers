#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

WP_VERSION=${1:-latest}
TMPDIR=${2:-/tmp}
DB_NAME=${3:-"wordpress_test"}
DB_USER=${4:-"root"}
DB_PASS=${5:-""}
DB_HOST=${6:-"127.0.0.1"}
SKIP_DB=${7:-""}
WP_TESTS_DIR=${WP_TESTS_DIR-$TMPDIR/wordpress-tests-lib}
WP_CORE_DIR=${WP_CORE_DIR-$TMPDIR/wordpress/}

download_wp --version="$WP_VERSION" --tmpdir="$TMPDIR"
setup_wp --version="$WP_VERSION"
install_test_suite

# Maybe install the database.
if [ -n "$SKIP_DB" ]; then
	install_db "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
fi
