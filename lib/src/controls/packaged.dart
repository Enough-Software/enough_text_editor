import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../editor.dart';
import '../editor_api.dart';
import '../models.dart';
import 'base.dart';

/// A combination of controls and editor for a simpler usage.
///
/// Like for the editor you can either use the `onCreated(EditorApi)` callback or a global key to get access to the state,
/// in this case the [PackagedTextEditorState]. With either the state or the [TextEditorApi] you can access the edited text with
/// ```dart
/// String edited = await editorApi.getText();
/// ```
class PackagedTextEditor extends StatefulWidget {
  /// Creates a new packaged text editor
  ///
  /// Set the [initialContent] to populate the editor with some existing text
  /// Set [expands] to let the editor set its height automatically - by default this is `true`.
  /// Define the [onCreated] `onCreated(TextEditorApi)` callback to get notified when the API is ready.
  /// Set [splitBlockquotes] to `false` in case block quotes should not be split when the user adds a newline in one - this defaults to `true`.
  /// Set [addDefaultSelectionMenuItems] to `false` when you do not want to have the default text selection items enabled.
  /// You can define your own custom context / text selection menu entries using [textSelectionMenuItems].
  /// Set [excludeDocumentLevelControls] to `true` in case controls that affect the whole document like the page background color should be excluded.
  const PackagedTextEditor({
    Key? key,
    this.initialContent = '',
    this.onCreated,
    this.addDefaultSelectionMenuItems = true,
    this.textSelectionMenuItems,
    this.isSingleLine = true,
    this.minLines,
  }) : super(key: key);

  /// Does this editor restrict itselft to a single lingle (`true` by default)
  final bool isSingleLine;

  /// The minimum shown lines
  final int? minLines;

  /// The initial input text
  final String initialContent;

  /// Defines if the default text selection menu items `𝗕` (bold), `𝑰` (italic), `U̲` (underlined),`T̶` (strikethrough) should be added - defaults to `true`.
  final bool addDefaultSelectionMenuItems;

  /// List of custom text selection / context menu items.
  final List<TextSelectionMenuItem>? textSelectionMenuItems;

  /// Define the `onCreated(EditorApi)` callback to get notified when the API is ready and to retrieve the end result.
  final void Function(TextEditorApi)? onCreated;

  @override
  PackagedTextEditorState createState() => PackagedTextEditorState();
}

/// The state for the [PackagedTextEditor] widget.
///
/// Only useful in combination with a global key.
class PackagedTextEditorState extends State<PackagedTextEditor> {
  /// The editor API, can be null until editor is initialized.
  TextEditorApi? editorApi;

  /// Retrieves the current text
  String getText() => editorApi?.getText() ?? '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (editorApi == null) ...{
          const PlatformProgressIndicator(),
        } else ...{
          TextEditorControls(
            editorApi: editorApi,
          ),
        },
        TextEditor(
          initialContent: widget.initialContent,
          addEditorSelectionMenuItems: widget.addDefaultSelectionMenuItems,
          textSelectionMenuItems: widget.textSelectionMenuItems,
          onCreated: _onCreated,
          isSingleLine: widget.isSingleLine,
          minLines: widget.minLines,
        ),
      ],
    );
  }

  void _onCreated(TextEditorApi api) {
    setState(() {
      editorApi = api;
    });
    final callback = widget.onCreated;
    if (callback != null) {
      callback(api);
    }
  }
}
