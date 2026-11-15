import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/features/bookmarks/bookmark_save.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/features/search/search_screen.dart';
import 'package:chrysotile_app/shared/widgets/brand_header.dart';
import 'package:chrysotile_app/shared/widgets/category_chip_bar.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:chrysotile_app/shared/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(homeLatestFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(homeFeedProvider);
    await Future.wait([
      ref.read(homeFeedProvider.future),
      ref.read(homeLatestFeedProvider.notifier).refresh(),
    ]);
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  /// After this many stories the feed drops the mixed layout (big cards,
  /// pairs) and continues as a plain list of [NewsListCard]s.
  static const _mixedLayoutLimit = 78;

  List<_FeedBlock> _buildBlocks(List<PostCard> items, FeedSection? strip) {
    final blocks = <_FeedBlock>[];
    var i = 0;
    var step = 0;
    while (i < items.length) {
      if (i >= _mixedLayoutLimit) {
        blocks.add(_FeedBlock(_BlockKind.list, [items[i]]));
        i += 1;
        continue;
      }
      switch (step % 4) {
        case 0:
          blocks.add(_FeedBlock(_BlockKind.big, items.skip(i).take(1).toList()));
          i += 1;
        case 2:
          blocks.add(_FeedBlock(_BlockKind.pair, items.skip(i).take(2).toList()));
          i += 2;
        default:
          for (var k = 0; k < 2 && i < items.length; k++) {
            blocks.add(
              _FeedBlock(_BlockKind.list, items.skip(i).take(1).toList()),
            );
            i += 1;
          }
      }
      step += 1;
      if (step == 3 && strip != null) {
        blocks.add(
          _FeedBlock(_BlockKind.carousel, strip.posts, title: strip.label),
        );
      }
    }
    return blocks;
  }

  void _bookmark(PostCard post) {
    handleBookmarkTap(context: context, ref: ref, post: post);
  }

  Widget _buildBlock(BuildContext context, _FeedBlock block) {
    switch (block.kind) {
      case _BlockKind.big:
        final bigPost = block.posts.first;
        return BigNewsCard(
          post: bigPost,
          bookmarked: ref.watch(isBookmarkedProvider(bigPost.id)),
          onTap: () => openArticle(context, bigPost.id),
          onBookmarkTap: () => _bookmark(bigPost),
        );
      case _BlockKind.pair:
        return NewsPairRow(
          posts: block.posts,
          onTap: (post) => openArticle(context, post.id),
        );
      case _BlockKind.carousel:
        return NewsCarousel(
          title: block.title.isNotEmpty ? block.title : 'Выбор редакции',
          posts: block.posts,
          onTap: (post) => openArticle(context, post.id),
        );
      case _BlockKind.list:
        final listPost = block.posts.first;
        return NewsListCard(
          post: listPost,
          bookmarked: ref.watch(isBookmarkedProvider(listPost.id)),
          onTap: () => openArticle(context, listPost.id),
          onBookmarkTap: () => _bookmark(listPost),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeFeedProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedSlug = ref.watch(homeCategoryFilterProvider);
    final latest = ref.watch(homeLatestFeedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: BrandHeader()),
              const SliverToBoxAdapter(
                child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFF9C9C9C)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: AppSearchField(
                    readOnly: true,
                    onTap: _openSearch,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  loading: () => const SizedBox(height: 28),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) => CategoryChipBar(
                    categories: categories,
                    selectedSlug: selectedSlug,
                    onSelected: (slug) {
                      ref.read(homeCategoryFilterProvider.notifier).state = slug;
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ...homeAsync.when(
                loading: () => [
                  const PrefixedSliverFill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, _) => [
                  PrefixedSliverFill(
                    child: ErrorState(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(homeFeedProvider),
                    ),
                  ),
                ],
                data: (home) {
                  final showHero = selectedSlug == null;
                  final feedItems = latest.items;

                  // Lead story: "Главное" for the full feed, first story of the
                  // chosen rubric otherwise.
                  PostCard? hero;
                  var rest = <PostCard>[];
                  if (showHero && home.hero.isNotEmpty) {
                    final lead = home.hero.first;
                    hero = lead;
                    rest = feedItems.where((p) => p.id != lead.id).toList();
                  } else if (feedItems.isNotEmpty) {
                    hero = feedItems.first;
                    rest = feedItems.skip(1).toList();
                  }

                  FeedSection? strip;
                  if (showHero) {
                    for (final section in home.sections) {
                      if (section.posts.length >= 3) {
                        strip = section;
                        break;
                      }
                    }
                  }
                  final blocks = _buildBlocks(rest, strip);

                  final heroPost = hero;

                  // Rubric switch: the lead story comes from the new page, so
                  // until it arrives show only a spinner. Otherwise the
                  // "Последние новости" title flashes first and "Главное"
                  // pops in above it once the page loads.
                  if (heroPost == null && latest.loading) {
                    return [
                      const PrefixedSliverFill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ];
                  }

                  return [
                    if (heroPost != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SectionTitle(
                            showHero ? 'Главное сегодня' : 'Главное',
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: HeroTodayCard(
                            post: heroPost,
                            onTap: () => openArticle(context, heroPost.id),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionTitle('Последние новости'),
                      ),
                    ),
                    const SpacedSliverBox(height: 12),
                    if (latest.loading && latest.items.isEmpty)
                      const PrefixedSliverFill(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (latest.error != null && latest.items.isEmpty)
                      PrefixedSliverFill(
                        child: ErrorState(
                          message: latest.error.toString(),
                          onRetry: () =>
                              ref.read(homeLatestFeedProvider.notifier).refresh(),
                        ),
                      )
                    else if (latest.items.isEmpty)
                      PrefixedSliverFill(
                        child: Center(
                          child: Text(
                            'Пока нет материалов',
                            style: TextStyle(
                              fontSize: 17,
                              color: isDark
                                  ? AppColors.darkTextSoft
                                  : AppColors.gray,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= blocks.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildBlock(context, blocks[index]);
                            },
                            childCount:
                                blocks.length + (latest.loadingMore ? 1 : 0),
                          ),
                        ),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrefixedSliverFill extends StatelessWidget {
  const PrefixedSliverFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: child,
    );
  }
}

class SpacedSliverBox extends StatelessWidget {
  const SpacedSliverBox({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}

enum _BlockKind { big, list, pair, carousel }

class _FeedBlock {
  const _FeedBlock(this.kind, this.posts, {this.title = ''});

  final _BlockKind kind;
  final List<PostCard> posts;
  final String title;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
