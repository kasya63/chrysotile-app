import 'dart:async';

import 'package:chrysotile_app/core/storage/search_history_store.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/features/bookmarks/bookmark_save.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/brand_header.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:chrysotile_app/shared/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _popularQueries = [
  'Житикара',
  'праздник',
  'экономика',
  'выборы',
  'культура',
  'происшествия',
  'спорт',
];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _historyStore = SearchHistoryStore();
  Timer? _debounce;
  String _query = '';
  PaginatedPosts? _results;
  Object? _error;
  bool _loading = false;
  bool _loadingMore = false;
  List<String> _recent = const [];
  bool _historyReady = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await _historyStore.load();
    if (!mounted) return;
    setState(() {
      _recent = items;
      _historyReady = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      final results = _results;
      if (results != null && results.hasMore && !_loadingMore) {
        _search(page: results.page + 1);
      }
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(value);
    });
  }

  void _runSearch(String value) {
    final trimmed = value.trim();
    if (trimmed == _query) {
      return;
    }
    setState(() {
      _query = trimmed;
      _results = null;
      _error = null;
    });
    if (trimmed.length >= 2) {
      _search(page: 1);
    }
  }

  void _applyQuery(String value) {
    _controller.text = value;
    _debounce?.cancel();
    _runSearch(value);
  }

  Future<void> _persistRecent(List<String> items) async {
    setState(() => _recent = items);
    await _historyStore.save(items);
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = const []);
    await _historyStore.clear();
  }

  Future<void> _search({required int page}) async {
    final query = _query;
    if (query.length < 2) {
      return;
    }

    setState(() {
      if (page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final pageResult = await ref.read(apiProvider).search(
            query: query,
            page: page,
          );
      if (!mounted || query != _query) {
        return;
      }
      setState(() {
        _results = page == 1
            ? pageResult
            : (_results?.merge(pageResult) ?? pageResult);
        _loading = false;
        _loadingMore = false;
      });
      if (page == 1) {
        final next = [
          query,
          ..._recent.where((item) => item != query),
        ].take(8).toList();
        await _persistRecent(next);
      }
    } catch (error) {
      if (!mounted || query != _query) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(child: BrandHeader()),
              ],
            ),
            const Divider(
              height: 0.5,
              thickness: 0.5,
              color: Color(0xFF9C9C9C),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Поиск',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppSearchField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onQueryChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      _runSearch(value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Популярные запросы',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularQueries.map((query) {
                      return ActionChip(
                        label: Text(
                          query,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.darkText : Colors.black,
                          ),
                        ),
                        onPressed: () => _applyQuery(query),
                        backgroundColor:
                            isDark ? AppColors.darkSurface : Colors.white,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.black.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Недавние',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkText : Colors.black,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _recent.isEmpty ? null : _clearRecent,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          textStyle: const TextStyle(fontSize: 13),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Очистить'),
                      ),
                    ],
                  ),
                  if (!_historyReady)
                    const SizedBox.shrink()
                  else if (_recent.isEmpty)
                    Text(
                      'История пуста',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextSoft
                            : AppColors.gray,
                      ),
                    )
                  else
                    ..._recent.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(
                          Icons.schedule,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSoft
                              : Colors.black54,
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.darkText : Colors.black,
                          ),
                        ),
                        onTap: () => _applyQuery(item),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Результаты',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildResults(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(bool isDark) {
    if (_query.length < 2) {
      return [
        Text(
          'Введите минимум 2 символа',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSoft : AppColors.gray,
          ),
        ),
      ];
    }

    if (_loading && _results == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    if (_error != null && _results == null) {
      return [
        ErrorState(
          message: _error.toString(),
          onRetry: () => _search(page: 1),
        ),
      ];
    }

    final results = _results;
    if (results == null || results.items.isEmpty) {
      return [
        Text(
          'Ничего не найдено',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSoft : AppColors.gray,
          ),
        ),
      ];
    }

    return [
      ...results.items.map((post) {
        final bookmarked = ref.watch(isBookmarkedProvider(post.id));
        return NewsListCard(
          post: post,
          bookmarked: bookmarked,
          onTap: () => openArticle(context, post.id),
          onBookmarkTap: () {
            handleBookmarkTap(
              context: context,
              ref: ref,
              post: post,
            );
          },
        );
      }),
      if (_loadingMore)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }
}
