#!/bin/bash
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
    echo "Unknown option: $i. Usage: ./bin/install-local-tests.sh --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --version=latest --tmpdir=/tmp --skip-db=true"
    exit 1
    ;;
  esac
done

# Run install-wp-tests.sh
echo "Installing local tests into ${TMPDIR}"
echo "Using WordPress version: ${WP_VERSION}"

if [ -z "$SKIP_DB" ]; then
  bash "$(dirname "$0")/install-wp-tests.sh" --version="$WP_VERSION" --tmpdir="$TMPDIR" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST"
else
  bash "$(dirname "$0")/install-wp-tests.sh" bash "$(dirname "$0")/install-wp-tests.sh" --version="$WP_VERSION" --tmpdir="$TMPDIR" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --skip-db=true
fi

# Run PHPUnit
pwd
echo "Running PHPUnit"
composer phpunit
