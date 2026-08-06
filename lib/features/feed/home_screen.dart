import 'package:chrysotile_app/core/theme/app_theme.dart';
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
                  final hero = home.hero.isNotEmpty ? home.hero.first : null;
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Главное сегодня',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkText
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hero != null) ...[
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: HeroTodayCard(
                            post: hero,
                            onTap: () => openArticle(context, hero.id),
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Последние новости',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? AppColors.darkText : Colors.black,
                          ),
                        ),
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
                              if (index >= latest.items.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final post = latest.items[index];
                              final bookmarked =
                                  ref.watch(isBookmarkedProvider(post.id));
                              return NewsListCard(
                                post: post,
                                bookmarked: bookmarked,
                                onTap: () => openArticle(context, post.id),
                                onBookmarkTap: () {
                                  ref
                                      .read(bookmarksProvider.notifier)
                                      .toggle(post);
                                },
                              );
                            },
                            childCount: latest.items.length +
                                (latest.loadingMore ? 1 : 0),
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
