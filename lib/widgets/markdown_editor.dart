import 'package:flutter/material.dart';
import '../core/codecs/markdown_codec.dart';
import '../core/model/rich_text_document.dart';
import '../core/model/block_node.dart';
import '../core/model/inline_node.dart';
import '../core/model/attributes.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    required this.controller,
    this.previewStyle,
  });

  final TextEditingController controller;
  final TextStyle? previewStyle;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final MarkdownCodec _codec;
  RichTextDocument? _document;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _codec = const MarkdownCodec();
    _parseMarkdown(widget.controller.text);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _parseMarkdown(widget.controller.text);
  }

  void _parseMarkdown(String text) {
    try {
      setState(() {
        _document = _codec.decode(text);
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Markdown here...',
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: _buildPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Parse error: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_document == null) {
      return const Center(
        child: Text('Nothing to preview'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _SimpleMarkdownRenderer(document: _document!),
    );
  }
}

class _SimpleMarkdownRenderer extends StatelessWidget {
  const _SimpleMarkdownRenderer({required this.document});

  final RichTextDocument document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: document.blocks.map((block) {
        return _buildBlock(context, block);
      }).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, BlockNode block) {
    if (block is TextBlockNode) {
      return _buildTextBlock(context, block);
    } else if (block is CodeBlockNode) {
      return _buildCodeBlock(context, block);
    } else if (block is DividerBlockNode) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(),
      );
    } else if (block is TableBlockNode) {
      return _buildTable(context, block);
    } else if (block is ImageBlockNode) {
      return _buildImage(context, block);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTextBlock(BuildContext context, TextBlockNode block) {
    final style = _getTextStyle(block);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.merge(style),
          children: block.content.map((node) {
            return _buildInlineNode(context, node);
          }).toList(),
        ),
      ),
    );
  }

  TextStyle _getTextStyle(TextBlockNode block) {
    if (block.type == BlockType.heading) {
      final level = block.attributes.level ?? 1;
      final sizes = {1: 24.0, 2: 20.0, 3: 18.0, 4: 16.0, 5: 14.0, 6: 12.0};
      return TextStyle(
        fontSize: sizes[level] ?? 14,
        fontWeight: FontWeight.bold,
      );
    }
    if (block.type == BlockType.quote) {
      return const TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
      );
    }
    return const TextStyle(fontSize: 14);
  }

  TextSpan _buildInlineNode(BuildContext context, InlineNode node) {
    if (node is TextRun) {
      var style = const TextStyle(fontSize: 14);
      final attrs = node.attributes;
      if (attrs.bold == true) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      if (attrs.italic == true) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      if (attrs.inlineCode == true) {
        style = style.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.shade200,
        );
      }
      if (attrs.lineThrough == true) {
        style = style.copyWith(decoration: TextDecoration.lineThrough);
      }
      if (attrs.underline == true) {
        style = style.copyWith(decoration: TextDecoration.underline);
      }
      if (attrs.color != null) {
        style = style.copyWith(color: Color(attrs.color!));
      }
      if (attrs.url != null) {
        style = style.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
      }
      return TextSpan(text: node.text, style: style);
    } else if (node is InlineEmbed) {
      return TextSpan(text: '[${node.embedType}]');
    }
    return const TextSpan(text: '');
  }

  Widget _buildCodeBlock(BuildContext context, CodeBlockNode block) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SelectableText(
        block.code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context, TableBlockNode block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: block.table.rows.map((row) {
            return TableRow(
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    cell.blocks
                        .whereType<TextBlockNode>()
                        .expand((b) => b.content)
                        .whereType<TextRun>()
                        .map((r) => r.text)
                        .join(),
                    style: cell.isHeader
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ImageBlockNode block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text('[Image: ${block.altText}]'),
    );
  }
}