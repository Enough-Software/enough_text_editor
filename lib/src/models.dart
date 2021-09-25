import 'package:flutter/widgets.dart';

import 'editor_api.dart';

/// Abstracts a text selection menu item.
class TextSelectionMenuItem {
  /// The text label of the item
  final String label;

  /// The callback
  final dynamic Function(TextEditorApi api) action;

  /// Creates a new selection menu item with the specified [label] and [action].
  TextSelectionMenuItem({required this.label, required this.action});
}
