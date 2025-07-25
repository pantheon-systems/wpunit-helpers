#!/usr/bin/env bash
set -e

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

main() {
	local DIRNAME
	DIRNAME=$(dirname "$0")
	local skip_nightly=false
	local skip_db=false
	local install_cmd=("bash" "${DIRNAME}/install-wp-tests.sh" "--dbpass=root")
	local install_cmd_skipdb=("${install_cmd[@]}" "--skip-db=true")

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
	if $skip_db; then
		"${install_cmd_skipdb[@]}"
	else
		"${install_cmd[@]}"
	fi

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 1]: Running PHPUnit on Single Site"
	composer phpunit --ansi

	"${install_cmd_skipdb[@]}"
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
	"${install_cmd_skipdb[@]}" --version=nightly

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 3]: Running PHPUnit on Single Site (Nightly WordPress)"
	composer phpunit --ansi

	echo '------------------------------------------'
	echo "🏃‍♂️ [Run 4]: Running PHPUnit on Multisite (Nightly WordPress)"
	WP_MULTISITE=1 composer phpunit --ansi
	
	echo "Done! ✅"
}

main "$@"