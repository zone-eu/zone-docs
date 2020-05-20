<?php
// phpcs:ignoreFile -- exclude from PHPcodesniffer tests
/*
 *
 *  This is a collection of shims for moving from legacy PHP versions to 5.6+
 *
 *  Add to your php.ini or .user.ini:
 *      auto_prepend_file = /var/www/php-shims.inc
 *
 *  Peeter Marvet / peeter@zone.ee 19-05-2020
 *
 *  Other resources:
 *      MySQL shim for PHP 7.x https://github.com/dshafik/php7-mysql-shim
 *
 */

if ( PHP_VERSION_ID >= 50600 ) {

	// re-introduce deprecated variables

	$HTTP_POST_VARS   = &$_POST;
	$HTTP_GET_VARS    = &$_GET;
	$HTTP_COOKIE_VARS = &$_COOKIE;

	$HTTP_SERVER_VARS  = &$_SERVER;
	$HTTP_POST_FILES   = &$_FILES;
	$HTTP_SESSION_VARS = &$_SESSION;
	$HTTP_ENV_VARS     = &$_ENV;

	// register globals - Matt Kukowski http://docs.php.net/manual/da/security.globals.php#113106
	// if you need  to implement register_globals() function see http://docs.php.net/manual/da/security.globals.php#82213

	if ( ! isset( $PXM_REG_GLOB ) ) {

		$PXM_REG_GLOB = 1;

		if ( ! ini_get( 'register_globals' ) ) {
			foreach ( array_merge( $_GET, $_POST ) as $key => $val ) {
				global $$key;
				$$key = ( get_magic_quotes_gpc() ) ? $val : addslashes( $val );
			}
		}
		if ( ! get_magic_quotes_gpc() ) {
			foreach ( $_POST as $key => $val ) {
				$_POST[ $key ] = addslashes( $val );
			}
			foreach ( $_GET as $key => $val ) {
				$_GET[ $key ] = addslashes( $val );
			}
		}
	}

	// replace removed session functions - partially from https://stackoverflow.com/questions/3682615/how-to-fix-the-session-register-deprecated-issue/59504007#59504007
	// (there's more magic there, but it requires runkit.so)

	if ( ! function_exists( 'session_register' ) ) {
		function session_register() {
			$register_vars = func_get_args();
			foreach ( $register_vars as $var_name ) {
				$_SESSION[ $var_name ] = $GLOBALS[ $var_name ];
				if ( ! ini_get( 'register_globals' ) ) {
					$GLOBALS[ $var_name ] = &$_SESSION[ $var_name ];
				}
			}
		}

		function session_is_registered( $var_name ) {
			return isset( $_SESSION[ $var_name ] );
		}

		function session_unregister( $var_name ) {
			unset( $_SESSION[ $var_name ] );
		}
	}
}
