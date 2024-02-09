#!/bin/bash
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
    echo "Unknown option: $i. Usage: ./bin/install-local-tests.sh --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --version=latest --tmpdir=/tmp --no-db"
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
  bash "$(dirname "$0")/install-wp-tests.sh" bash "$(dirname "$0")/install-wp-tests.sh" --version="$WP_VERSION" --tmpdir="$TMPDIR" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --no-db
fi

# Run PHPUnit
echo "Running PHPUnit"
composer phpunit
