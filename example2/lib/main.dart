import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:enough_text_editor/enough_text_editor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PlatformApp(
      title: 'enough_text_editor Demo',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      home: EditorPage(),
    );
  }
}

/// Example how to use the simplified [PackagedTextEditor] that combines the default controls and the editor.
class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  TextEditorApi? _editorApi;
  bool _isSingleLine = false;
  bool _showEditorChrome = true;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('PackagedTextEditor'),
        trailingActions: [
          DensePlatformIconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final text = _editorApi!.getText();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ResultScreen(text: text),
                ),
              );
            },
          ),
          DensePlatformIconButton(
            icon: const Icon(Icons.looks_two),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomScrollEditorPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              PlatformCheckboxListTile(
                title: const Text('is single line'),
                value: _isSingleLine,
                onChanged: (value) =>
                    setState(() => _isSingleLine = value ?? true),
              ),
              PlatformCheckboxListTile(
                title: const Text('show editor chrome'),
                value: _showEditorChrome,
                onChanged: (value) =>
                    setState(() => _showEditorChrome = value ?? true),
              ),
              if (_showEditorChrome) ...{
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PackagedTextEditor(
                    maxLines: _isSingleLine ? 1 : null,
                    minLines: _isSingleLine ? null : 3,
                    onCreated: (api) {
                      _editorApi = api;
                    },
                    initialContent:
                        '''Hello world, this is an example text for you to edit!''',
                  ),
                ),
              } else ...{
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextEditor(
                    maxLines: _isSingleLine ? 1 : null,
                    minLines: _isSingleLine ? null : 3,
                    onCreated: (api) {
                      _editorApi = api;
                    },
                    initialContent:
                        '''Hello world, this is an example text for you to edit!''',
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Example how to use editor within a a CustomScrollView
class CustomScrollEditorPage extends StatefulWidget {
  const CustomScrollEditorPage({Key? key}) : super(key: key);

  @override
  State<CustomScrollEditorPage> createState() => _CustomScrollEditorPageState();
}

class _CustomScrollEditorPageState extends State<CustomScrollEditorPage> {
  TextEditorApi? _editorApi;
  bool _isSingleLine = false;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PlatformSliverAppBar(
            title: const Text('Sticky controls'),
            floating: false,
            pinned: true,
            stretch: true,
            actions: [
              DensePlatformIconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = _editorApi!.getText();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ResultScreen(text: text),
                    ),
                  );
                },
              ),
              DensePlatformIconButton(
                icon: const Icon(Icons.looks_one),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditorPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: DecoratedPlatformTextField(
                decoration:
                    InputDecoration(hintText: 'Recipient (normal TextField)'),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: TextEditor(
                decoration: InputDecoration(hintText: 'Subject (TextEditor)'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: PlatformCheckboxListTile(
                title: const Text('is single line'),
                value: _isSingleLine,
                onChanged: (value) =>
                    setState(() => _isSingleLine = value ?? true),
              ),
            ),
          ),
          if (_editorApi != null) ...{
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverHeaderTextEditorControls(editorApi: _editorApi),
            ),
          },
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextEditor(
                maxLines: _isSingleLine ? 1 : null,
                minLines: _isSingleLine ? null : 3,
                onCreated: (api) {
                  setState(() {
                    _editorApi = api;
                  });
                },
                initialContent:
                    '''Lorem ipsum dolor\n\nsit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,\n\nsed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.\n\nAt vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.''',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String text;
  const ResultScreen({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: const Text('Result'),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SelectableText(text),
        )),
      ),
    );
  }
}
