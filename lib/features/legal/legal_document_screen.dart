import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Не удалось загрузить документ.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final blocks = _parseMarkdownLite(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              for (final block in blocks) ...[
                if (block is _HeadingBlock)
                  Padding(
                    padding: EdgeInsets.only(
                      top: block.level == 1 ? 4 : 20,
                      bottom: 8,
                    ),
                    child: SelectableText(
                      block.text,
                      style: (block.level == 1
                              ? textTheme.headlineSmall
                              : textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  )
                else if (block is _ParagraphBlock)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SelectableText(
                      block.text,
                      style: textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

sealed class _MdBlock {
  const _MdBlock();
}

class _HeadingBlock extends _MdBlock {
  const _HeadingBlock(this.level, this.text);

  final int level;
  final String text;
}

class _ParagraphBlock extends _MdBlock {
  const _ParagraphBlock(this.text);

  final String text;
}

List<_MdBlock> _parseMarkdownLite(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_MdBlock>[];
  final paragraph = StringBuffer();

  void flushParagraph() {
    final text = paragraph.toString().trim();
    paragraph.clear();
    if (text.isNotEmpty) {
      blocks.add(_ParagraphBlock(text));
    }
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();
    final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line.trimLeft());
    if (heading != null) {
      flushParagraph();
      blocks.add(
        _HeadingBlock(heading.group(1)!.length, _stripInlineMd(heading.group(2)!)),
      );
      continue;
    }

    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    if (paragraph.isNotEmpty) {
      paragraph.write(' ');
    }
    paragraph.write(_stripInlineMd(line.trim()));
  }

  flushParagraph();
  return blocks;
}

String _stripInlineMd(String input) {
  var text = input;
  text = text.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (match) => match.group(1)!,
  );
  return text;
}
