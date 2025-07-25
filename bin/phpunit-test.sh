#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

main() {
	local DIRNAME
	DIRNAME=$(dirname "$0")
	local skip_nightly=false
	local skip_db=false

	# Super simple arg parsing
	for arg in "$@"; do
		if [[ "$arg" == "--skip-nightly" ]]; then
			skip_nightly=true
			break
		fi
		if [[ "$arg" == "--skip-db" ]]; then
			skip_db=true
			break
		fi
	done

	echo "🤔 Installing WP Unit tests..."
	bash "${DIRNAME}/install-wp-tests.sh" --dbpass=root --skip-db="$skip_db"

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 1]: Running PHPUnit on Single Site"
	composer phpunit --ansi

	bash "${DIRNAME}/install-wp-tests.sh" --dbpass=root --skip-db=true
	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 2]: Running PHPUnit on Multisite"
	WP_MULTISITE=1 composer phpunit --ansi

	if $skip_nightly; then
		echo "Skipping nightly WordPress tests..."
		echo "Done! ✅"
		return
	fi

	echo "🧹 Removing files before testing nightly WP..."
	cleanup

	echo "🤔 Installing WP Unit tests with WP nightly version..."
	bash "${DIRNAME}/install-wp-tests.sh" --dbpass=root --version=nightly --skip-db=true

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 3]: Running PHPUnit on Single Site (Nightly WordPress)"
	composer phpunit --ansi

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 4]: Running PHPUnit on Multisite (Nightly WordPress)"
	WP_MULTISITE=1 composer phpunit --ansi
	
	echo "Done! ✅"
}

main "$@"