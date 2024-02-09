#!/bin/bash
set -e

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

# Check if a version was provided as an argument.
if [ $# -gt 0 ]; then
  WP_VERSION=$1
else
  # Request version.
  echo "Which version of WordPress would you like to test against? (latest, nightly, or a version number) Leave blank for latest."
  read -r WP_VERSION
fi

# Initialize variables with default values
TMPDIR="/tmp"
DB_NAME="wordpress_test"
DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"
WP_VERSION=${WP_VERSION:-latest}
SKIP_DB=""

# Parse command-line arguments
for i in "$@"
do
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
    *)
    # unknown option
    usage "./install-local-tests.sh"
    exit 1
    ;;
esac
done

# Run install-wp-tests.sh
echo "Installing local tests into ${TMPDIR}"
echo "Using WordPress version: ${WP_VERSION}"
bash "$(dirname "$0")/install-wp-tests.sh" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_HOST" "$WP_VERSION" "$SKIP_DB"

# Run PHPUnit
echo "Running PHPUnit"
composer phpunit
