#!/usr/bin/env bash
set -ex

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

# Initialize variables with default values
TMPDIR="/tmp"
DB_NAME="wordpress_test"
DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"
WP_VERSION=${WP_VERSION:-latest}
SKIP_DB=""

# Parse command-line arguments
for i in "$@"; do
	case $i in
		--dbname=*)
		DB_NAME="${i#*=}"
		shift
		;;
		--dbuser=*)
		DB_USER="${i#*=}"
		shift
		;;
		--dbpass=*)
		DB_PASS="${i#*=}"
		shift
		;;
		--dbhost=*)
		DB_HOST="${i#*=}"
		shift
		;;
		--version=*)
		WP_VERSION="${i#*=}"
		shift
		;;
		--no-db)
		SKIP_DB="true"
		shift
		;;
		--tmpdir=*)
		TMPDIR="${i#*=}"
		shift
		;;
		*)
		# unknown option
		echo "Unknown option: $i. Usage: ./bin/install-wp-tests.sh --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --version=latest --tmpdir=/tmp --no-db"
		exit 1
		;;
	esac
done

WP_TESTS_DIR=${WP_TESTS_DIR-$TMPDIR/wordpress-tests-lib}
WP_CORE_DIR=${WP_CORE_DIR-$TMPDIR/wordpress/}

download_wp --version="$WP_VERSION" --tmpdir="$TMPDIR"
setup_wp --version="$WP_VERSION"
install_test_suite

# Maybe install the database.
if [ -n "$SKIP_DB" ]; then
	install_db "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
fi
