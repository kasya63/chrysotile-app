import 'package:chrysotile_app/core/models/auth_models.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:chrysotile_app/features/auth/login_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(apiProvider).createComment(
            postId: widget.postId,
            content: text,
          );
      _controller.clear();
      ref.invalidate(commentsProvider(widget.postId));
      _toast('Комментарий добавлен');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось отправить комментарий');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _edit(ArticleComment comment) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditCommentDialog(initial: comment.content),
    );
    if (text == null || text.trim().isEmpty || text.trim() == comment.content) {
      return;
    }
    try {
      await ref.read(apiProvider).updateComment(
            commentId: comment.id,
            content: text.trim(),
          );
      ref.invalidate(commentsProvider(widget.postId));
      _toast('Комментарий изменён');
    } catch (_) {
      _toast('Не удалось изменить комментарий');
    }
  }

  Future<void> _delete(ArticleComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(apiProvider).deleteComment(comment.id);
      ref.invalidate(commentsProvider(widget.postId));
      _toast('Комментарий удалён');
    } catch (_) {
      _toast('Не удалось удалить комментарий');
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    final loggedIn = ref.watch(isLoggedInProvider);
    final me = ref.watch(authControllerProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Комментарии',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (!loggedIn)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Чтобы оставить комментарий, войдите в аккаунт.',
                    style: TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 5,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(
              hintText: 'Ваш комментарий…',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) =>
              const Text('Не удалось загрузить комментарии'),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'Пока нет комментариев',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              );
            }

            return Column(
              children: items
                  .map(
                    (comment) => _CommentTile(
                      comment: comment,
                      isOwn: me != null &&
                          comment.authorId != 0 &&
                          comment.authorId == me.id,
                      onEdit: () => _edit(comment),
                      onDelete: () => _delete(comment),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.onEdit,
    required this.onDelete,
  });

  final ArticleComment comment;
  final bool isOwn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final soft = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.author,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                comment.dateDisplay,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: soft,
                    ),
              ),
              if (isOwn)
                PopupMenuButton<String>(
                  tooltip: 'Действия',
                  icon: Icon(Icons.more_vert, color: soft),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Редактировать'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 17, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initial});

  final String initial;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать комментарий'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        style: const TextStyle(fontSize: 17),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
