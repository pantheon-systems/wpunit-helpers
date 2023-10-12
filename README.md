# WPUnit Helpers
[![Lint](https://github.com/pantheon-systems/wpunit-helpers/actions/workflows/lint.yml/badge.svg)](https://github.com/pantheon-systems/wpunit-helpers/actions/workflows/lint.yml) ![GitHub](https://img.shields.io/github/license/pantheon-systems/wpunit-helpers) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/pantheon-systems/wpunit-helpers) [![Unofficial Support](https://img.shields.io/badge/Pantheon-Unofficial%20Support-yellow?logo=pantheon&color=FFDC28)](https://docs.pantheon.io/oss-support-levels#unofficial-support)

Unified scripts for installing and running automated WP Unit Tests.

## What is this?

This is a set of scripts that can be used in a WordPress plugin or theme repository to run automated tests using the WP Unit Test Framework built on top of PHPUnit. The Composer plugin will install these scripts into the dependent project's `bin` directory, allowing you to add helper scripts to your `composer.json`.

## What's included?

* `install-wp-tests.sh` - The _de facto_ standard script for installing the WP Unit Test Framework.
* `install-local-tests.sh` - A helper script for installing WP Unit Tests locally. See [Local Testing](#local-testing) for more information.
* `phpunit-test.sh` - A helper script for running WP Unit Tests that is intended for use in CI.

## Installation

Use Composer to install this package as a development dependency:

```bash
composer require --dev pantheon-systems/wpunit-helpers
```

On installation, the Composer plugin will copy the scripts into the `bin` directory of the dependent project. You can then add the scripts to your `composer.json`:

```json
{
	"scripts": {
		"phpunit": "phpunit --do-not-cache-result",
		"test": "@phpunit",
		"test:install": "bin/install-local-tests.sh --no-db",
		"test:install:withdb": "bin/install-local-tests.sh"
	}
}
```

## Local Testing
The `install-local-tests.sh` script is highly configurable to allow for a variety of local environment setups. Any parameter that could be passed into `install-wp-tests.sh` is set up as an optional flag in `install-local-tests.sh`. By default, the script with no flags will assume that a new database should be created as `root` with no password.

### Flags

#### `--no-db`
This flag will skip the database creation step. This is useful if you are using a local database that is already set up.

#### `--dbname`
This flag will set the name of the database to be created. The default value is `wordpress_test`.

#### `--dbuser`
This flag will set the username of the database user to be created. The default value is `root`.

#### `--dbpass`
This flag will set the password of the database user to be created. The default value is an empty string.

#### `--dbhost`
This flag will set the host of the database to be created. The default value is `127.0.0.1`.

#### `--wpversion`
This flag will set the version of WordPress to be installed. The default value is `latest`. Using `nightly` here will use the latest nightly build of WordPress.
