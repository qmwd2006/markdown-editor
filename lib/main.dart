import 'package:flutter/material.dart';
import 'widgets/markdown_editor.dart';

void main() {
  runApp(const MarkdownEditorApp());
}

class MarkdownEditorApp extends StatelessWidget {
  const MarkdownEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const MarkdownEditorPage(),
    );
  }
}

class MarkdownEditorPage extends StatefulWidget {
  const MarkdownEditorPage({super.key});

  @override
  State<MarkdownEditorPage> createState() => _MarkdownEditorPageState();
}

class _MarkdownEditorPageState extends State<MarkdownEditorPage> {
  final TextEditingController _controller = TextEditingController(
    text: '''# Welcome to Markdown Editor

This is a **simple** Markdown editor with *live preview*.

## Features

- Edit Markdown on the left
- Preview on the right
- Real-time rendering

## Code Example

```dart
void main() {
  print('Hello, World!');
}
```

## Table

| Name | Age |
|------|-----|
| Alice | 25 |
| Bob | 30 |

> This is a blockquote.

---

Start editing to see the preview update!''',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Markdown',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Markdown copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed: () {
              _controller.clear();
            },
          ),
        ],
      ),
      body: MarkdownEditor(
        controller: _controller,
      ),
    );
  }
}