#!/usr/bin/env bash
set -e

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
	# Skip 'bash' argument
	if [[ $i == "bash" ]]; then
		echo "Ignoring 'bash' argument"
		continue
	fi

	# Skip the script path argument
	if [[ $i == *install-wp-tests.sh ]]; then
		echo "Ignoring script path argument"
		continue
	fi

	case $i in
		--dbname=*)
		DB_NAME="${i#*=}"
		;;
		--dbuser=*)
		DB_USER="${i#*=}"
		;;
		--dbpass=*)
		DB_PASS="${i#*=}"
		;;
		--dbhost=*)
		DB_HOST="${i#*=}"
		;;
		--version=*)
		WP_VERSION="${i#*=}"
		;;
		--skip-db=*)
		SKIP_DB="true"
		;;
		--tmpdir=*)
		TMPDIR="${i#*=}"
		;;
		*)
		# unknown option
		echo "Unknown option: $i. Usage: ./bin/install-wp-tests.sh --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --version=latest --tmpdir=/tmp --skip-db=true"
		exit 1
		;;
	esac
done

WP_TESTS_DIR=${WP_TESTS_DIR:-$TMPDIR/wordpress-tests-lib}
WP_CORE_DIR=${WP_CORE_DIR:-$TMPDIR/wordpress/}

# Maybe install the database.
if [ -z "$SKIP_DB" ]; then
	echo "Installing database"
	install_db "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
fi

download_wp --version="$WP_VERSION" --tmpdir="$TMPDIR"

SETUP_ARGS=(--version="$WP_VERSION" --tmpdir="$TMPDIR" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST")

if [ "$WP_VERSION" == "nightly" ]; then
	echo "Setting up WP nightly"
	setup_wp_nightly "${SETUP_ARGS[@]}"
else
	echo "Setting up WP $WP_VERSION"
	setup_wp "${SETUP_ARGS[@]}"
fi

echo "Installing WordPress test suite"
install_test_suite "$WP_VERSION" "$TMPDIR" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST"
