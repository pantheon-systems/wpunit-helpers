#!/bin/bash

download() {
    if which curl &> /dev/null; then  
        curl -s "$1" > "$2";  
    elif which wget &> /dev/null; then  
        wget -nv -O "$2" "$1"  
    else  
        echo "Missing curl or wget" >&2  
        exit 1  
    fi  
}

download_wp() {
	TMPDIR="/tmp"
	WP_VERSION="latest"

	for i in "$@"; do
		case $i in
			--version=*)
			WP_VERSION="${i#*=}"
			shift
			;;
			--tmpdir=*)
			TMPDIR="${i#*=}"
			shift
			;;
			*)
			# unknown option
			echo "Unknown option: $i. Usage: download_wp --version=latest --tmpdir=/tmp"
			exit 1
			;;
		esac
	done

	# Check for WP-CLI. If the wp command does not exist, exit.
	if ! which wp &> /dev/null; then
		echo "WP-CLI is not installed. Exiting."
		exit 1
	fi

	echo "Downloading WordPress version: ${WP_VERSION}"
	wp core download --version="$WP_VERSION" --path="${TMPDIR}/wordpress"
}

setup_wp() {
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
			echo "Unknown option: $i. Usage: setup_wp --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --version=latest --tmpdir=/tmp --no-db"
			exit 1
			;;
		esac
	done

	download http://api.wordpress.org/core/version-check/1.7/ "$TMPDIR"/wp-latest.json	
	echo "Creating wp-config.php"
	wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --dbprefix="wptests_" --path="${TMPDIR}/wordpress"
	wp core install --url=localhost --title=Test --admin_user=admin --admin_password=password --admin_email=test@dev.null --path="${TMPDIR}/wordpress"
}

setup_wp_nightly() {
	WP_DIR="/tmp/wordpress"

	for i in "$@"; do
		case $i in
			--wpdir=*)
			WP_DIR="${i#*=}"
			shift
			;;
			*)
			# unknown option
			echo "Unknown option: $i. Usage: setup_wp_nightly --wpdir=/tmp/wordpress"
			exit 1
			;;
		esac
	done

	setup_wp --version="nightly"
	# If nightly version of WP is installed, install latest Gutenberg plugin and activate it.
	echo "Installing Gutenberg plugin"
	wp plugin install gutenberg --activate --path="$WP_DIR"
}

install_test_suite() {
	# portable in-place argument for both GNU sed and Mac OSX sed
	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i .bak'
	else
		local ioption='-i'
	fi

	# set up testing suite if it doesn't yet exist
	if [ ! -d "$WP_TESTS_DIR" ]; then
		# set up testing suite
		mkdir -p "$WP_TESTS_DIR"
		svn co --quiet --ignore-externals https://develop.svn.wordpress.org/"${WP_TESTS_TAG}"/tests/phpunit/includes/ "$WP_TESTS_DIR"/includes
		svn co --quiet --ignore-externals https://develop.svn.wordpress.org/"${WP_TESTS_TAG}"/tests/phpunit/data/ "$WP_TESTS_DIR"/data
	fi

	if [ ! -f wp-tests-config.php ]; then
		download https://develop.svn.wordpress.org/"${WP_TESTS_TAG}"/wp-tests-config-sample.php "$WP_TESTS_DIR"/wp-tests-config.php
		# remove all forward slashes in the end
		WP_CORE_DIR="${WP_CORE_DIR%/}"
		sed "$ioption" "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_TESTS_DIR"/wp-tests-config.php
		sed "$ioption" "s/youremptytestdbnamehere/$DB_NAME/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed "$ioption" "s/yourusernamehere/$DB_USER/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed "$ioption" "s/yourpasswordhere/$DB_PASS/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed "$ioption" "s|localhost|${DB_HOST}|" "$WP_TESTS_DIR"/wp-tests-config.php
	fi
}

install_db() {
	DB_HOST=${1:-"127.0.0.1"}
	DB_NAME=${2:-"wordpress_test"}
	DB_USER=${3:-"root"}
	DB_PASS=${4:-""}
	SKIP_DB=${5:-""}

	if [ "${SKIP_DB_CREATE}" = "true" ]; then
		return 0
	fi

	# parse DB_HOST for port or socket references
	IFS=':' read -ra PARTS <<< "${DB_HOST}"
	local DB_HOSTNAME=${PARTS[0]};
	local DB_SOCK_OR_PORT=${PARTS[1]};
	local EXTRA=""

	if [ -n "$DB_HOSTNAME" ] ; then
		if echo "$DB_SOCK_OR_PORT" | grep -qe '^[0-9]\{1,\}$'; then
			EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
		elif [ -n "$DB_SOCK_OR_PORT" ] ; then
			EXTRA=" --socket=$DB_SOCK_OR_PORT"
		elif [ -n "$DB_HOSTNAME" ] ; then
			EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
		fi
	fi

	# create database
	mysqladmin create "$DB_NAME" --user="$DB_USER" --password="$DB_PASS""$EXTRA"
}

cleanup() {
	WPDIR=${1:-"/tmp/wordpress"}
	WP_TESTS_DIR=${2:-"/tmp/wordpress-tests-lib"}
	WP_VERSION_JSON=${3:-"/tmp/wp-latest.json"}

	wp db reset --yes --path="$WPDIR"
	rm -rf "$WPDIR"
	rm -rf "$WP_TESTS_DIR"
	rm -f "$WP_VERSION_JSON"
}

# Display usage information
usage() {
  echo "Usage:"
  echo "$0 [--dbname=wordpress_test] [--dbuser=root] [--dbpass=''] [--dbhost=127.0.0.1] [--wpversion=latest] [--no-db]"
}
