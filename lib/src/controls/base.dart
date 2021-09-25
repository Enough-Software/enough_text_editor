import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';

import '../editor.dart';
import '../editor_api.dart';
import 'controls.dart';

/// Use the `HtmlEditorApiWidget` to provide the `HtmlEditorApi` to widgets further down the widget tree.
///
/// Example:
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///     return HtmlEditorApiWidget(
///      editorApi: _editorApi,
///      child: YourCustomWidgetHere(),
///     );
///   }
/// ```
/// Now in any other widgets below you can access the API in this way:
/// ```dart
///  final api = HtmlEditorApiWidget.of(context)!.editorApi;
/// ```
class TextEditorApiWidget extends InheritedWidget {
  final TextEditorApi editorApi;

  /// Creates a new HtmlEditorApiWidget with the specified [editorApi] and [child]
  const TextEditorApiWidget(
      {Key? key, required this.editorApi, required Widget child})
      : super(key: key, child: child);

  /// Retrieves the widget instance from the given [context].
  static TextEditorApiWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TextEditorApiWidget>();
  }

  @override
  bool updateShouldNotify(TextEditorApiWidget oldWidget) {
    return true;
  }
}

/// Predefined editor controls.
///
/// With `enough_text_editor` you can create your very own editor controls.
class TextEditorControls extends StatefulWidget {
  final GlobalKey<TextEditorState>? editorKey;
  final TextEditorApi? editorApi;
  final Widget? prefix;
  final Widget? suffix;

  /// Creates a new `HtmlEditorControls`.
  ///
  /// You have to specify either the [editorApi] or the [editorKey].
  /// Optionally specify your own [prefix] and [suffix] widgets. These widgets can access the `HtmlEditorApi` by calling `HtmlEditorApiWidget.of(context)`, e.g. `final api = HtmlEditorApiWidget.of(context)!.editorApi;`
  const TextEditorControls({
    Key? key,
    this.editorApi,
    this.editorKey,
    this.prefix,
    this.suffix,
  })  : assert(editorApi != null || editorKey != null,
            'Please define either the editorApi or editorKey pararameter.'),
        super(key: key);

  @override
  _TextEditorControlsState createState() => _TextEditorControlsState();
}

class _TextEditorControlsState extends State<TextEditorControls> {
  late TextEditorApi _editorApi;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApi();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const PlatformProgressIndicator();
    }
    final prefix = widget.prefix;
    final suffix = widget.suffix;
    final size = MediaQuery.of(context).size;
    return TextEditorApiWidget(
      editorApi: _editorApi,
      child: SizedBox(
        width: size.width,
        height: 50,
        child: Material(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (prefix != null) ...{
                prefix,
              },
              const BaseFormatButtons(),
              const FontFamilyDropdown(),
              if (suffix != null) ...{
                suffix,
              },
            ],
          ),
        ),
      ),
    );
  }

  void _initApi() {
    final key = widget.editorKey;
    final api = widget.editorApi;
    if (key != null) {
      // in init state, the editorKey.currentState is still null,
      // so wait for after the first run
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        final stateApi = key.currentState!.api;
        setState(() {
          _editorApi = stateApi;
          _isInitialized = true;
        });
      });
    } else if (api != null) {
      _editorApi = api;
      _isInitialized = true;
    }
  }
}
