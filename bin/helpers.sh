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
	DB_PASS="root"
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
		--wpversion=*)
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
		echo "Unknown option: $i. Usage: setup_wp --dbname=wordpress_test --dbuser=root --dbpass=root --dbhost=localhost --wpversion=latest --tmpdir=/tmp --no-db"
		exit 1
		;;
	esac
	done

	download http://api.wordpress.org/core/version-check/1.7/ "$TMPDIR"/wp-latest.json	
	echo "Creating wp-config.php"
	wp config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="$DB_HOST" --dbprefix="wptests_" --path="${TMPDIR}/wordpress"
	wp core install --url=localhost --title=Test --admin_user=admin --admin_password=password --admin_email=test@dev.null --path="${TMPDIR}/wordpress"
}
	# If nightly version of WP is installed, install latest Gutenberg plugin and activate it.
	echo "Installing Gutenberg plugin"
	wp plugin install gutenberg --activate --path="/tmp/wordpress"
}

install_wp() {

	if [ -d "$WP_CORE_DIR" ]; then
		return;
	fi

	mkdir -p "$WP_CORE_DIR"

	if [[ "$WP_VERSION" == 'nightly' || "$WP_VERSION" == 'trunk' ]]; then
		mkdir -p "$TMPDIR"/wordpress-nightly
		download https://wordpress.org/nightly-builds/wordpress-latest.zip  "$TMPDIR"/wordpress-nightly/wordpress-nightly.zip
		unzip -q "$TMPDIR"/wordpress-nightly/wordpress-nightly.zip -d "$TMPDIR"/wordpress-nightly/
		mv "$TMPDIR"/wordpress-nightly/wordpress/* "$WP_CORE_DIR"
	else
		if [ "$WP_VERSION" == 'latest' ]; then
			local ARCHIVE_NAME='latest'
		elif [[ "$WP_VERSION" =~ [0-9]+\.[0-9]+ ]]; then
			# https serves multiple offers, whereas http serves single.
			download https://api.wordpress.org/core/version-check/1.7/ "$TMPDIR"/wp-latest.json
			if [[ "$WP_VERSION" =~ [0-9]+\.[0-9]+\.[0] ]]; then
				# version x.x.0 means the first release of the major version, so strip off the .0 and download version x.x
				LATEST_VERSION=${WP_VERSION%??}
			else
				# otherwise, scan the releases and get the most up to date minor version of the major release

				# Assign with string replacement, escaping dots
				local VERSION_ESCAPED
				VERSION_ESCAPED="${WP_VERSION//./\\.}"
				LATEST_VERSION=$(grep -o '"version":"'"$VERSION_ESCAPED"'[^"]*' "$TMPDIR"/wp-latest.json | sed 's/"version":"//' | head -1)
			fi
			if [[ -z "$LATEST_VERSION" ]]; then
				local ARCHIVE_NAME="wordpress-$WP_VERSION"
			else
				local ARCHIVE_NAME="wordpress-$LATEST_VERSION"
			fi
		else
			local ARCHIVE_NAME="wordpress-$WP_VERSION"
		fi
		download https://wordpress.org/"${ARCHIVE_NAME}".tar.gz  "$TMPDIR"/wordpress.tar.gz
		tar --strip-components=1 -zxmf "$TMPDIR"/wordpress.tar.gz -C "$WP_CORE_DIR"
	fi

	download https://raw.github.com/markoheijnen/wp-mysqli/master/db.php "$WP_CORE_DIR"/wp-content/db.php
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

# Display usage information
usage() {
  echo "Usage:"
  echo "$0 [--dbname=wordpress_test] [--dbuser=root] [--dbpass=''] [--dbhost=127.0.0.1] [--wpversion=latest] [--no-db]"
}
