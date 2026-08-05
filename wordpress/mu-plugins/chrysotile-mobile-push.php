<?php
/**
 * Plugin Name: Chrysotile Mobile Push
 * Description: Device registration and FCM push on post publish.
 * Version: 0.1.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Chrysotile_Mobile_Push {
	private const NS           = 'chrysotile/v1';
	private const TABLE_SUFFIX = 'chrysotile_devices';
	private const SA_PATH      = '/var/www/chrysotile-fcm-sa.json';

	public static function boot(): void {
		add_action( 'init', array( self::class, 'maybe_create_table' ) );
		add_action( 'rest_api_init', array( self::class, 'register_routes' ) );
		add_action( 'transition_post_status', array( self::class, 'on_status_change' ), 10, 3 );
	}

	public static function maybe_create_table(): void {
		$version = (string) get_option( 'chrysotile_devices_db_version', '' );
		if ( '1' !== $version ) {
			self::create_table();
			update_option( 'chrysotile_devices_db_version', '1' );
		}
	}

	private static function table_name(): string {
		global $wpdb;
		return $wpdb->prefix . self::TABLE_SUFFIX;
	}

	private static function create_table(): void {
		global $wpdb;
		$table   = self::table_name();
		$charset = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			fcm_token VARCHAR(255) NOT NULL,
			platform VARCHAR(16) NOT NULL DEFAULT 'unknown',
			user_id BIGINT UNSIGNED NULL,
			topics LONGTEXT NULL,
			app_version VARCHAR(32) NULL,
			updated_at DATETIME NOT NULL,
			created_at DATETIME NOT NULL,
			PRIMARY KEY  (id),
			UNIQUE KEY fcm_token (fcm_token),
			KEY user_id (user_id)
		) {$charset};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );
	}

	public static function register_routes(): void {
		register_rest_route(
			self::NS,
			'/devices',
			array(
				array(
					'methods'             => WP_REST_Server::CREATABLE,
					'callback'            => array( self::class, 'upsert_device' ),
					'permission_callback' => '__return_true',
				),
				array(
					'methods'             => 'DELETE',
					'callback'            => array( self::class, 'delete_device' ),
					'permission_callback' => '__return_true',
				),
			)
		);
	}

	public static function upsert_device( WP_REST_Request $request ): WP_REST_Response {
		global $wpdb;

		$token    = sanitize_text_field( (string) $request->get_param( 'fcm_token' ) );
		$platform = sanitize_key( (string) $request->get_param( 'platform' ) );
		$topics   = $request->get_param( 'topics' );
		$version  = sanitize_text_field( (string) $request->get_param( 'app_version' ) );

		if ( '' === $token || strlen( $token ) < 20 ) {
			return new WP_REST_Response( array( 'message' => 'Invalid FCM token.' ), 400 );
		}

		if ( ! in_array( $platform, array( 'ios', 'android', 'unknown' ), true ) ) {
			$platform = 'unknown';
		}

		if ( ! is_array( $topics ) ) {
			$topics = array( 'cat_glavnye' );
		}

		$topics = array_values(
			array_unique(
				array_filter(
					array_map(
						static function ( $topic ) {
							$topic = sanitize_key( (string) $topic );
							return '' !== $topic ? $topic : null;
						},
						$topics
					)
				)
			)
		);

		if ( empty( $topics ) ) {
			$topics = array( 'cat_glavnye' );
		}

		$user_id = get_current_user_id();
		$now     = current_time( 'mysql', true );
		$table   = self::table_name();

		$existing = $wpdb->get_var(
			$wpdb->prepare( "SELECT id FROM {$table} WHERE fcm_token = %s", $token )
		);

		$data = array(
			'fcm_token'   => $token,
			'platform'    => $platform,
			'user_id'     => $user_id > 0 ? $user_id : null,
			'topics'      => wp_json_encode( $topics ),
			'app_version' => $version,
			'updated_at'  => $now,
		);

		if ( $existing ) {
			$wpdb->update( $table, $data, array( 'id' => (int) $existing ) );
			$id = (int) $existing;
		} else {
			$data['created_at'] = $now;
			$wpdb->insert( $table, $data );
			$id = (int) $wpdb->insert_id;
		}

		return new WP_REST_Response(
			array(
				'id'     => $id,
				'topics' => $topics,
			),
			200
		);
	}

	public static function delete_device( WP_REST_Request $request ): WP_REST_Response {
		global $wpdb;

		$token = sanitize_text_field( (string) $request->get_param( 'fcm_token' ) );
		if ( '' === $token ) {
			return new WP_REST_Response( array( 'message' => 'Token required.' ), 400 );
		}

		$wpdb->delete( self::table_name(), array( 'fcm_token' => $token ) );

		return new WP_REST_Response( array( 'ok' => true ), 200 );
	}

	public static function on_status_change( string $new_status, string $old_status, $post ): void {
		if ( 'publish' !== $new_status || 'publish' === $old_status ) {
			return;
		}

		if ( ! $post instanceof WP_Post || 'post' !== $post->post_type ) {
			return;
		}

		// Avoid blocking the editor: schedule async send.
		wp_schedule_single_event( time() + 5, 'chrysotile_send_push_for_post', array( (int) $post->ID ) );
	}
}

add_action(
	'chrysotile_send_push_for_post',
	static function ( int $post_id ): void {
		Chrysotile_FCM::send_for_post( $post_id );
	}
);

final class Chrysotile_FCM {
	private const SA_PATH = '/var/www/chrysotile-fcm-sa.json';

	public static function send_for_post( int $post_id ): void {
		$post = get_post( $post_id );
		if ( ! $post instanceof WP_Post || 'publish' !== $post->post_status ) {
			return;
		}

		$topics = self::topics_for_post( $post_id );
		if ( empty( $topics ) ) {
			$topics = array( 'cat_glavnye' );
		}

		$title = html_entity_decode( wp_strip_all_tags( get_the_title( $post ) ), ENT_QUOTES, 'UTF-8' );
		$body  = html_entity_decode( wp_strip_all_tags( get_the_excerpt( $post ) ), ENT_QUOTES, 'UTF-8' );
		if ( '' === $body ) {
			$body = 'Новая публикация на Chrysotile';
		}
		$body = wp_html_excerpt( $body, 120, '…' );

		$data = array(
			'post_id' => (string) $post_id,
			'type'    => 'new_post',
		);

		foreach ( $topics as $topic ) {
			self::send_to_topic( $topic, $title, $body, $data );
		}
	}

	private static function topics_for_post( int $post_id ): array {
		$categories = get_the_category( $post_id );
		$topics     = array();

		foreach ( $categories as $category ) {
			if ( $category instanceof WP_Term ) {
				$topics[] = 'cat_' . sanitize_key( $category->slug );
			}
		}

		return array_values( array_unique( $topics ) );
	}

	private static function send_to_topic( string $topic, string $title, string $body, array $data ): void {
		$access_token = self::access_token();
		$project_id   = self::project_id();

		if ( ! $access_token || ! $project_id ) {
			error_log( 'Chrysotile FCM: service account missing or invalid at ' . self::SA_PATH );
			return;
		}

		$payload = array(
			'message' => array(
				'topic'        => $topic,
				'notification' => array(
					'title' => $title,
					'body'  => $body,
				),
				'data'         => $data,
				'android'      => array(
					'priority' => 'HIGH',
				),
				'apns'         => array(
					'headers' => array(
						'apns-priority' => '10',
					),
					'payload' => array(
						'aps' => array(
							'sound' => 'default',
						),
					),
				),
			),
		);

		$response = wp_remote_post(
			'https://fcm.googleapis.com/v1/projects/' . rawurlencode( $project_id ) . '/messages:send',
			array(
				'timeout' => 20,
				'headers' => array(
					'Authorization' => 'Bearer ' . $access_token,
					'Content-Type'  => 'application/json',
				),
				'body'    => wp_json_encode( $payload ),
			)
		);

		if ( is_wp_error( $response ) ) {
			error_log( 'Chrysotile FCM error: ' . $response->get_error_message() );
			return;
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		if ( $code < 200 || $code >= 300 ) {
			error_log( 'Chrysotile FCM HTTP ' . $code . ': ' . wp_remote_retrieve_body( $response ) );
		}
	}

	private static function project_id(): ?string {
		$sa = self::service_account();
		return is_array( $sa ) && ! empty( $sa['project_id'] ) ? (string) $sa['project_id'] : null;
	}

	private static function service_account(): ?array {
		if ( ! is_readable( self::SA_PATH ) ) {
			return null;
		}

		$raw = file_get_contents( self::SA_PATH );
		if ( false === $raw ) {
			return null;
		}

		$data = json_decode( $raw, true );
		return is_array( $data ) ? $data : null;
	}

	private static function access_token(): ?string {
		$cached = get_transient( 'chrysotile_fcm_access_token' );
		if ( is_string( $cached ) && '' !== $cached ) {
			return $cached;
		}

		$sa = self::service_account();
		if ( ! $sa || empty( $sa['client_email'] ) || empty( $sa['private_key'] ) ) {
			return null;
		}

		$now   = time();
		$header = self::b64url( wp_json_encode( array( 'alg' => 'RS256', 'typ' => 'JWT' ) ) );
		$claim  = self::b64url(
			wp_json_encode(
				array(
					'iss'   => $sa['client_email'],
					'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
					'aud'   => 'https://oauth2.googleapis.com/token',
					'iat'   => $now,
					'exp'   => $now + 3600,
				)
			)
		);

		$unsigned = $header . '.' . $claim;
		$key      = openssl_pkey_get_private( $sa['private_key'] );
		if ( ! $key ) {
			return null;
		}

		$signature = '';
		$ok        = openssl_sign( $unsigned, $signature, $key, OPENSSL_ALGO_SHA256 );
		if ( ! $ok ) {
			return null;
		}

		$jwt = $unsigned . '.' . self::b64url( $signature );

		$response = wp_remote_post(
			'https://oauth2.googleapis.com/token',
			array(
				'timeout' => 20,
				'body'    => array(
					'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
					'assertion'  => $jwt,
				),
			)
		);

		if ( is_wp_error( $response ) ) {
			return null;
		}

		$body = json_decode( (string) wp_remote_retrieve_body( $response ), true );
		if ( ! is_array( $body ) || empty( $body['access_token'] ) ) {
			return null;
		}

		$token = (string) $body['access_token'];
		set_transient( 'chrysotile_fcm_access_token', $token, 50 * MINUTE_IN_SECONDS );

		return $token;
	}

	private static function b64url( string $data ): string {
		return rtrim( strtr( base64_encode( $data ), '+/', '-_' ), '=' );
	}
}

Chrysotile_Mobile_Push::boot();
