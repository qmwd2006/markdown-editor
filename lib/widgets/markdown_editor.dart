import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/codecs/markdown_codec.dart';
import '../core/model/rich_text_document.dart';
import '../core/model/block_node.dart';
import '../core/model/inline_node.dart';

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
        // Editor panel
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
        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        // Preview panel
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

  Widget _buildBlock(BuildContext context, dynamic block) {
    // Import block_node.dart types
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
    final style = _getTextStyleForType(block.type);
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

  TextStyle _getTextStyleForType(String type) {
    switch (type) {
      case 'h1':
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case 'h2':
        return const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case 'h3':
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      case 'h4':
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      case 'h5':
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
      case 'h6':
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
      case 'blockquote':
        return const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        );
      case 'listItem':
        return const TextStyle(fontSize: 14);
      default:
        return const TextStyle(fontSize: 14);
    }
  }

  TextSpan _buildInlineNode(BuildContext context, dynamic node) {
    if (node is TextRun) {
      var style = TextStyle(fontSize: 14);
      if (node.attributes.bold == true) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      if (node.attributes.italic == true) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      }
      if (node.attributes.code == true) {
        style = style.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.grey.shade200,
        );
      }
      if (node.attributes.strikethrough == true) {
        style = style.copyWith(decoration: TextDecoration.lineThrough);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }

  Widget _buildImage(BuildContext context, ImageBlockNode block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text('[Image: ${block.alt}]'),
    );
  }
}