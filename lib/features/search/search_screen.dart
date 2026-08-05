import 'dart:async';

import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _fieldText = '';
  PaginatedPosts? _results;
  Object? _error;
  bool _loading = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final text = _controller.text;
      if (text != _fieldText) {
        setState(() => _fieldText = text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
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
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                final trimmed = value.trim();
                setState(() {
                  _query = trimmed;
                  _results = null;
                  _error = null;
                });
                if (trimmed.length >= 2) {
                  _search(page: 1);
                }
              },
              decoration: InputDecoration(
                hintText: 'Найти новости…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _fieldText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _results = null;
                            _error = null;
                            _loading = false;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_query.length < 2) {
      return Center(
        child: Text(
          'Введите минимум 2 символа',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    if (_loading && _results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _results == null) {
      return ErrorState(
        message: _error.toString(),
        onRetry: () => _search(page: 1),
      );
    }

    final results = _results;
    if (results == null || results.items.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: results.items.length + (results.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= results.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => _search(page: results.page + 1),
                      child: const Text('Показать ещё'),
                    ),
            ),
          );
        }

        final post = results.items[index];
        return CompactPostTile(
          post: post,
          onTap: () => openArticle(context, post.id),
        );
      },
    );
  }
}
