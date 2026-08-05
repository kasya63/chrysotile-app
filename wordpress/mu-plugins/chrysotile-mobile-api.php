<?php
/**
 * Plugin Name: Chrysotile Mobile API
 * Description: Lightweight REST API for the Chrysotile mobile app.
 * Version: 0.1.0
 * Author: Chrysotile
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Chrysotile_Mobile_API {
	private const NS = 'chrysotile/v1';

	private const GENERIC_CATEGORY_SLUGS = array(
		'vse-novosti',
		'vse-rubriki',
		'all-news',
		'all-categories',
		'uncategorized',
		'glavnye',
	);

	private const HOME_SECTIONS = array(
		array(
			'slug'  => 'gosudarstvo',
			'label' => 'В стране',
			'limit' => 20,
		),
		array(
			'slug'  => 'region',
			'label' => 'В регионе',
			'limit' => 16,
		),
		array(
			'slug'  => 'people',
			'label' => 'Люди',
			'limit' => 8,
		),
	);

	public static function boot(): void {
		add_action( 'rest_api_init', array( self::class, 'register_routes' ) );
		add_filter( 'rest_pre_serve_request', array( self::class, 'add_cache_headers' ), 10, 4 );
	}

	public static function register_routes(): void {
		register_rest_route(
			self::NS,
			'/home',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'get_home' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			self::NS,
			'/feed',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'get_feed' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'category' => array(
						'type'              => 'string',
						'required'          => false,
						'sanitize_callback' => 'sanitize_title',
					),
					'page'     => array(
						'type'    => 'integer',
						'default' => 1,
						'minimum' => 1,
					),
					'per_page' => array(
						'type'    => 'integer',
						'default' => 20,
						'minimum' => 1,
						'maximum' => 50,
					),
				),
			)
		);

		register_rest_route(
			self::NS,
			'/posts/(?P<id>\d+)',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'get_post' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'id' => array(
						'type'     => 'integer',
						'required' => true,
					),
				),
			)
		);

		register_rest_route(
			self::NS,
			'/categories',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'get_categories' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			self::NS,
			'/search',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'search_posts' ),
				'permission_callback' => '__return_true',
				'args'                => array(
					'q'        => array(
						'type'              => 'string',
						'required'          => true,
						'sanitize_callback' => 'sanitize_text_field',
					),
					'page'     => array(
						'type'    => 'integer',
						'default' => 1,
						'minimum' => 1,
					),
					'per_page' => array(
						'type'    => 'integer',
						'default' => 20,
						'minimum' => 1,
						'maximum' => 50,
					),
				),
			)
		);

		register_rest_route(
			self::NS,
			'/posts/(?P<id>\d+)/view',
			array(
				'methods'             => WP_REST_Server::CREATABLE,
				'callback'            => array( self::class, 'track_view' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			self::NS,
			'/auth/register',
			array(
				'methods'             => WP_REST_Server::CREATABLE,
				'callback'            => array( self::class, 'register_user' ),
				'permission_callback' => '__return_true',
			)
		);

		register_rest_route(
			self::NS,
			'/auth/me',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( self::class, 'get_me' ),
				'permission_callback' => static function () {
					return is_user_logged_in();
				},
			)
		);

		register_rest_route(
			self::NS,
			'/posts/(?P<id>\d+)/comments',
			array(
				array(
					'methods'             => WP_REST_Server::READABLE,
					'callback'            => array( self::class, 'get_comments' ),
					'permission_callback' => '__return_true',
				),
				array(
					'methods'             => WP_REST_Server::CREATABLE,
					'callback'            => array( self::class, 'create_comment' ),
					'permission_callback' => static function () {
						return is_user_logged_in();
					},
				),
			)
		);
	}

	public static function add_cache_headers( $served, $result, $request, $server ) {
		$route = $request->get_route();
		if ( ! is_string( $route ) || strpos( $route, '/' . self::NS . '/' ) !== 0 ) {
			return $served;
		}

		if ( 'GET' !== $request->get_method() ) {
			return $served;
		}

		// Do not edge-cache auth/me or comment lists (may include pending own comments).
		if ( false !== strpos( $route, '/auth/' ) || false !== strpos( $route, '/comments' ) ) {
			header( 'Cache-Control: private, no-store' );
			return $served;
		}

		header( 'Cache-Control: public, max-age=300, s-maxage=300' );

		return $served;
	}

	public static function get_home( WP_REST_Request $request ): WP_REST_Response {
		$hero = self::query_posts(
			array(
				'posts_per_page' => 5,
				'category_name'  => 'glavnye',
			)
		);

		$sections = array();
		foreach ( self::HOME_SECTIONS as $section ) {
			$term = get_term_by( 'slug', $section['slug'], 'category' );
			if ( ! $term instanceof WP_Term ) {
				continue;
			}

			$posts = self::query_posts(
				array(
					'posts_per_page' => (int) $section['limit'],
					'cat'            => (int) $term->term_id,
				)
			);

			$sections[] = array(
				'slug'   => $section['slug'],
				'label'  => $section['label'],
				'posts'  => $posts['items'],
				'total'  => $posts['total'],
			);
		}

		return new WP_REST_Response(
			array(
				'hero'     => $hero['items'],
				'sections' => $sections,
			),
			200
		);
	}

	public static function get_feed( WP_REST_Request $request ): WP_REST_Response {
		$category = (string) $request->get_param( 'category' );
		$page     = max( 1, (int) $request->get_param( 'page' ) );
		$per_page = max( 1, min( 50, (int) $request->get_param( 'per_page' ) ) );

		$args = array(
			'posts_per_page' => $per_page,
			'paged'          => $page,
		);

		if ( '' !== $category ) {
			$args['category_name'] = $category;
		}

		$result = self::query_posts( $args );

		return new WP_REST_Response( $result, 200 );
	}

	public static function get_post( WP_REST_Request $request ): WP_REST_Response {
		$post_id = (int) $request->get_param( 'id' );
		$post    = get_post( $post_id );

		if ( ! $post instanceof WP_Post || 'publish' !== $post->post_status || 'post' !== $post->post_type ) {
			return new WP_REST_Response( array( 'message' => 'Post not found.' ), 404 );
		}

		return new WP_REST_Response( self::format_post_detail( $post ), 200 );
	}

	public static function get_categories(): WP_REST_Response {
		$slugs = array( 'gosudarstvo', 'region', 'people', 'society', 'special_projects', 'special-projects', 'video' );
		$items = array();

		foreach ( $slugs as $slug ) {
			$term = get_term_by( 'slug', $slug, 'category' );
			if ( ! $term instanceof WP_Term ) {
				continue;
			}

			$items[] = array(
				'id'    => (int) $term->term_id,
				'slug'  => $term->slug,
				'name'  => $term->name,
				'count' => (int) $term->count,
			);
		}

		return new WP_REST_Response( array( 'items' => $items ), 200 );
	}

	public static function search_posts( WP_REST_Request $request ): WP_REST_Response {
		$query = trim( (string) $request->get_param( 'q' ) );
		if ( '' === $query ) {
			return new WP_REST_Response( array( 'items' => array(), 'total' => 0, 'page' => 1, 'per_page' => 20 ), 200 );
		}

		$page     = max( 1, (int) $request->get_param( 'page' ) );
		$per_page = max( 1, min( 50, (int) $request->get_param( 'per_page' ) ) );

		$result = self::query_posts(
			array(
				'posts_per_page' => $per_page,
				'paged'          => $page,
				's'              => $query,
			)
		);

		return new WP_REST_Response( $result, 200 );
	}

	public static function track_view( WP_REST_Request $request ): WP_REST_Response {
		$post_id = (int) $request->get_param( 'id' );
		$post    = get_post( $post_id );

		if ( ! $post instanceof WP_Post || 'publish' !== $post->post_status ) {
			return new WP_REST_Response( array( 'message' => 'Post not found.' ), 404 );
		}

		$views = max( 0, (int) get_post_meta( $post_id, 'chrysotile_views', true ) );
		update_post_meta( $post_id, 'chrysotile_views', $views + 1 );

		return new WP_REST_Response( array( 'views' => $views + 1 ), 200 );
	}

	public static function register_user( WP_REST_Request $request ) {
		$email    = sanitize_email( (string) $request->get_param( 'email' ) );
		$password = (string) $request->get_param( 'password' );
		$name     = sanitize_text_field( (string) $request->get_param( 'name' ) );

		if ( ! is_email( $email ) ) {
			return new WP_REST_Response( array( 'message' => 'Некорректный email.' ), 400 );
		}

		if ( strlen( $password ) < 8 ) {
			return new WP_REST_Response( array( 'message' => 'Пароль должен быть не короче 8 символов.' ), 400 );
		}

		if ( email_exists( $email ) ) {
			return new WP_REST_Response( array( 'message' => 'Пользователь с таким email уже есть.' ), 409 );
		}

		$username_base = sanitize_user( current( explode( '@', $email ) ), true );
		if ( '' === $username_base ) {
			$username_base = 'user';
		}

		$username = $username_base;
		$i        = 1;
		while ( username_exists( $username ) ) {
			$username = $username_base . $i;
			++$i;
		}

		$user_id = wp_insert_user(
			array(
				'user_login'   => $username,
				'user_email'   => $email,
				'user_pass'    => $password,
				'display_name' => '' !== $name ? $name : $username,
				'role'         => 'subscriber',
			)
		);

		if ( is_wp_error( $user_id ) ) {
			return new WP_REST_Response( array( 'message' => $user_id->get_error_message() ), 400 );
		}

		$token_request = new WP_REST_Request( 'POST', '/jwt-auth/v1/token' );
		$token_request->set_param( 'username', $email );
		$token_request->set_param( 'password', $password );
		$token_response = rest_do_request( $token_request );
		$token_data     = $token_response->get_data();

		if ( $token_response->is_error() || ! is_array( $token_data ) || empty( $token_data['token'] ) ) {
			return new WP_REST_Response(
				array(
					'message' => 'Аккаунт создан, но не удалось выдать токен. Войдите вручную.',
					'user'    => self::format_user( (int) $user_id ),
				),
				201
			);
		}

		return new WP_REST_Response(
			array(
				'token'             => $token_data['token'],
				'user_email'        => $token_data['user_email'] ?? $email,
				'user_nicename'     => $token_data['user_nicename'] ?? $username,
				'user_display_name' => $token_data['user_display_name'] ?? ( '' !== $name ? $name : $username ),
				'user'              => self::format_user( (int) $user_id ),
			),
			201
		);
	}

	public static function get_me(): WP_REST_Response {
		$user_id = get_current_user_id();
		if ( $user_id <= 0 ) {
			return new WP_REST_Response( array( 'message' => 'Unauthorized' ), 401 );
		}

		return new WP_REST_Response( self::format_user( $user_id ), 200 );
	}

	public static function get_comments( WP_REST_Request $request ): WP_REST_Response {
		$post_id = (int) $request->get_param( 'id' );
		$post    = get_post( $post_id );

		if ( ! $post instanceof WP_Post || 'publish' !== $post->post_status ) {
			return new WP_REST_Response( array( 'message' => 'Post not found.' ), 404 );
		}

		$current_user = get_current_user_id();
		$status       = array( 'approve' );
		if ( $current_user > 0 ) {
			$status[] = 'hold';
		}

		$comments = get_comments(
			array(
				'post_id' => $post_id,
				'status'  => $status,
				'orderby' => 'comment_date_gmt',
				'order'   => 'ASC',
				'number'  => 100,
			)
		);

		$items = array();
		foreach ( $comments as $comment ) {
			if ( ! $comment instanceof WP_Comment ) {
				continue;
			}

			$is_hold = '0' === (string) $comment->comment_approved;
			if ( $is_hold && (int) $comment->user_id !== $current_user ) {
				continue;
			}

			$items[] = self::format_comment( $comment );
		}

		return new WP_REST_Response( array( 'items' => $items ), 200 );
	}

	public static function create_comment( WP_REST_Request $request ) {
		$post_id = (int) $request->get_param( 'id' );
		$post    = get_post( $post_id );
		$user    = wp_get_current_user();

		if ( ! $post instanceof WP_Post || 'publish' !== $post->post_status ) {
			return new WP_REST_Response( array( 'message' => 'Post not found.' ), 404 );
		}

		if ( ! $user->exists() ) {
			return new WP_REST_Response( array( 'message' => 'Unauthorized' ), 401 );
		}

		$content  = trim( wp_strip_all_tags( (string) $request->get_param( 'content' ) ) );
		$parent   = max( 0, (int) $request->get_param( 'parent' ) );

		if ( '' === $content ) {
			return new WP_REST_Response( array( 'message' => 'Комментарий не может быть пустым.' ), 400 );
		}

		if ( strlen( $content ) > 2000 ) {
			return new WP_REST_Response( array( 'message' => 'Слишком длинный комментарий.' ), 400 );
		}

		$comment_id = wp_insert_comment(
			array(
				'comment_post_ID'      => $post_id,
				'comment_author'       => $user->display_name,
				'comment_author_email' => $user->user_email,
				'comment_author_url'   => '',
				'comment_content'      => $content,
				'comment_type'         => 'comment',
				'comment_parent'       => $parent,
				'user_id'              => $user->ID,
				'comment_approved'     => 0, // Premoderation.
			)
		);

		if ( ! $comment_id ) {
			return new WP_REST_Response( array( 'message' => 'Не удалось сохранить комментарий.' ), 500 );
		}

		$comment = get_comment( $comment_id );
		if ( ! $comment instanceof WP_Comment ) {
			return new WP_REST_Response( array( 'message' => 'Не удалось сохранить комментарий.' ), 500 );
		}

		return new WP_REST_Response( self::format_comment( $comment ), 201 );
	}

	private static function format_user( int $user_id ): array {
		$user = get_userdata( $user_id );

		return array(
			'id'           => $user_id,
			'email'        => $user ? $user->user_email : '',
			'display_name' => $user ? $user->display_name : '',
			'nicename'     => $user ? $user->user_nicename : '',
		);
	}

	private static function format_comment( WP_Comment $comment ): array {
		return array(
			'id'           => (int) $comment->comment_ID,
			'post_id'      => (int) $comment->comment_post_ID,
			'parent'       => (int) $comment->comment_parent,
			'author'       => $comment->comment_author,
			'author_id'    => (int) $comment->user_id,
			'content'      => $comment->comment_content,
			'date'         => get_comment_date( 'c', $comment ),
			'date_display' => get_comment_date( '', $comment ),
			'status'       => '1' === (string) $comment->comment_approved ? 'approved' : 'pending',
		);
	}

	private static function query_posts( array $args ): array {
		$query_args = wp_parse_args(
			$args,
			array(
				'post_type'           => 'post',
				'post_status'         => 'publish',
				'orderby'             => 'date',
				'order'               => 'DESC',
				'ignore_sticky_posts' => true,
			)
		);

		$query = new WP_Query( $query_args );
		$items = array();

		foreach ( $query->posts as $post ) {
			if ( $post instanceof WP_Post ) {
				$items[] = self::format_post_card( $post );
			}
		}

		return array(
			'items'    => $items,
			'total'    => (int) $query->found_posts,
			'page'     => max( 1, (int) ( $query_args['paged'] ?? 1 ) ),
			'per_page' => (int) $query_args['posts_per_page'],
		);
	}

	private static function format_post_card( WP_Post $post ): array {
		$categories = self::display_categories( $post->ID );

		return array(
			'id'           => (int) $post->ID,
			'title'        => html_entity_decode( wp_strip_all_tags( get_the_title( $post ) ), ENT_QUOTES, 'UTF-8' ),
			'subtitle'     => self::get_subtitle( $post->ID ),
			'excerpt'      => html_entity_decode( wp_strip_all_tags( get_the_excerpt( $post ) ), ENT_QUOTES, 'UTF-8' ),
			'date'         => get_the_date( 'c', $post ),
			'date_display' => get_the_date( '', $post ),
			'permalink'    => get_permalink( $post ),
			'image'        => self::get_image( $post->ID, 'large' ),
			'thumbnail'    => self::get_image( $post->ID, 'medium_large' ),
			'categories'   => $categories,
			'reading_min'  => self::reading_minutes( $post->ID ),
			'views'        => self::get_views( $post->ID ),
		);
	}

	private static function format_post_detail( WP_Post $post ): array {
		$card    = self::format_post_card( $post );
		$content = apply_filters( 'the_content', $post->post_content );
		$author  = (int) $post->post_author;
		$tags    = array();

		foreach ( get_the_tags( $post->ID ) ?: array() as $tag ) {
			if ( $tag instanceof WP_Term ) {
				$tags[] = array(
					'id'   => (int) $tag->term_id,
					'slug' => $tag->slug,
					'name' => $tag->name,
				);
			}
		}

		$related = self::query_posts(
			array(
				'posts_per_page' => 3,
				'post__not_in'   => array( $post->ID ),
				'orderby'        => 'meta_value_num',
				'meta_key'       => 'chrysotile_views',
				'order'          => 'DESC',
				'date_query'     => array(
					array(
						'after' => '30 days ago',
					),
				),
			)
		);

		$card['content_html'] = $content;
		$card['author']       = array(
			'id'   => $author,
			'name' => get_the_author_meta( 'display_name', $author ),
		);
		$card['tags']         = $tags;
		$card['related']      = $related['items'];

		return $card;
	}

	private static function display_categories( int $post_id ): array {
		$categories = get_the_category( $post_id );
		$items      = array();

		foreach ( $categories as $category ) {
			if ( ! $category instanceof WP_Term ) {
				continue;
			}

			if ( in_array( $category->slug, self::GENERIC_CATEGORY_SLUGS, true ) ) {
				continue;
			}

			$items[] = array(
				'id'   => (int) $category->term_id,
				'slug' => $category->slug,
				'name' => $category->name,
			);
		}

		return $items;
	}

	private static function get_subtitle( int $post_id ): string {
		$subtitle = get_post_meta( $post_id, 'chrysotile_subtitle', true );

		return is_string( $subtitle ) ? trim( $subtitle ) : '';
	}

	private static function get_views( int $post_id ): int {
		return max( 0, (int) get_post_meta( $post_id, 'chrysotile_views', true ) );
	}

	private static function reading_minutes( int $post_id ): int {
		$content = (string) get_post_field( 'post_content', $post_id );
		$words   = str_word_count( wp_strip_all_tags( $content ) );

		return max( 1, (int) ceil( $words / 200 ) );
	}

	private static function get_image( int $post_id, string $size ): ?array {
		$thumb_id = (int) get_post_thumbnail_id( $post_id );
		if ( $thumb_id <= 0 ) {
			return null;
		}

		$src = wp_get_attachment_image_src( $thumb_id, $size );
		if ( ! is_array( $src ) ) {
			return null;
		}

		return array(
			'url'    => $src[0],
			'width'  => (int) $src[1],
			'height' => (int) $src[2],
		);
	}
}

Chrysotile_Mobile_API::boot();
