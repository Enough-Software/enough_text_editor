
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'editor.dart';
import 'package:enough_ascii_art/enough_ascii_art.dart';

/// API to control the `HtmlEditor`.
///
/// Get access to this API either by waiting for the `HtmlEditor.onCreated()` callback or by accessing
/// the `HtmlEditorState` with a `GlobalKey<HtmlEditorState>`.
class TextEditorApi {
  // final TextEditorState _editorState;
  final TextEditingController _controller;
  TextSelection _selection;
  UnicodeFont _currentFont = UnicodeFont.normal;
  final FocusNode _focusNode;
  String _previousText;
  final _fontListeners = <void Function(UnicodeFont font)>[];

  bool _ignoreUpdateCall = false;
  bool _regainedFocus = false;

  TextEditorApi(
    TextEditorState state,
    TextEditingController controller,
    FocusNode focusNode,
  )   : //_editorState = state,
        _controller = controller,
        _focusNode = focusNode,
        _selection = controller.selection,
        _previousText = controller.text {
    _controller.addListener(_onUpdated);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onUpdated() {
    final selection = _controller.selection;
    // print(
    //     'onUpdated: ignore=$_ignoreUpdateCall focus=${_focusNode.hasFocus} selection: $selection, start=${selection.start}, isCollapsed=${selection.isCollapsed}  font=$_currentFont'); // text=${_controller.text}
    if (!_focusNode.hasFocus || selection.baseOffset == -1) {
      return;
    }
    if (_ignoreUpdateCall) {
      _ignoreUpdateCall = false;
      return;
    }
    final text = _controller.text;
    if (_regainedFocus) {
      _regainedFocus = false;
      if ((_selection.baseOffset > 0) &&
          (selection.baseOffset >= text.length - 1)) {
        // print('re-select previous selection $_selection');
        _controller.selection = _selection;
        return;
      }
    }
    _selection = selection;
    final previousText = _previousText;
    if (text != previousText) {
      _previousText = text;
      if (text.length > previousText.length &&
          selection.isCollapsed &&
          _currentFont != UnicodeFont.normal) {
        // text has been added
        final enteredTextFull = text.substring(
            selection.start - (text.length - previousText.length),
            selection.start);
        final convertedEnteredText =
            UnicodeFontConverter.encode(enteredTextFull, _currentFont);
        if (convertedEnteredText != enteredTextFull) {
          final buffer = StringBuffer();
          if (selection.start > enteredTextFull.length) {
            buffer.write(
                text.substring(0, selection.start - enteredTextFull.length));
          }
          buffer.write(convertedEnteredText);
          buffer.write(text.substring(selection.start));
          setText(buffer.toString());
          int diff = convertedEnteredText.length - enteredTextFull.length;
          if (diff != 0) {
            final newOffset = selection.baseOffset + diff;
            _controller.selection = selection.copyWith(
                baseOffset: newOffset, extentOffset: newOffset);
          }
        }
        return;
      }
    }
    if (selection.start > 0 && selection.isCollapsed) {
      final previousFont = _currentFont;
      final textPart = _controller.text.substring(0, selection.start);
      // rather check font from end: getFontFromEndOf(text);
      final currentFont = UnicodeFontConverter.getFontFromTextEnd(textPart);
      if (currentFont != previousFont) {
        // the font has changed:
        _notifyFontChanged(currentFont);
      }
    }
  }

  void _onFocusChanged() {
    // print('_onFocusChanged - hasFocus: ${_focusNode.hasFocus}');
    if (!_focusNode.hasFocus) {
      // print('_onFocusChanged storing ${_controller.selection}');
      _selection = _controller.selection;
    } else {
      _regainedFocus = true;
      //   print('focus: has selection $_selection');
    }
  }

  /// Adds callback for font changes unless it has been added before
  void addFontListener(void Function(UnicodeFont font) onChanged) {
    if (!_fontListeners.contains(onChanged)) {
      _fontListeners.add(onChanged);
    }
  }

  /// Removes the registration for the specified font listener callback
  bool removeFontListener(void Function(UnicodeFont font) onChanged) =>
      _fontListeners.remove(onChanged);

  void unfocus(BuildContext context) async {
    FocusScope.of(context).unfocus();
  }

  /// Formats the current text to be bold
  void formatBold() {
    _formatWithFont(_currentFont.toBoldVariant());
  }

  /// Formats the current text to be italic
  void formatItalic() {
    _formatWithFont(_currentFont.toItalicVariant());
  }

  /// Formats the current text to be underlined
  void formatUnderline() {
    _formatWithFont(UnicodeFont.underlinedSingle);
  }

  /// Formats the current text to be striked through
  void formatStrikeThrough() {
    _formatWithFont(UnicodeFont.strikethroughSingle);
  }

  /// Sets the [font] of the selected text
  void setFont(UnicodeFont font) {
    _formatWithFont(font);
    _notifyFontChanged(font);
  }

  /// Inserts the given plain [text] at the insertion point (replaces selection).
  void insertText(String text) {
    final selection = _selection;
    if (selection.isCollapsed) {
      if (selection.start == -1) {
        setText(getText() + text);
      } else {
        final existingText = getText();
        final buffer = StringBuffer();
        buffer.write(existingText.substring(0, selection.start));
        buffer.write(text);
        if (selection.start < existingText.length - 1) {
          buffer.write(existingText.substring(selection.start));
        }
        final newOffset = selection.baseOffset + text.length;
        setText(buffer.toString());
        _selection =
            selection.copyWith(baseOffset: newOffset, extentOffset: newOffset);
        _controller.selection = _selection;
      }
    } else {
      // replace the selection:
      final existingText = getText();
      final buffer = StringBuffer();
      buffer.write(existingText.substring(0, selection.start));
      buffer.write(text);
      if (selection.end < existingText.length - 1) {
        buffer.write(existingText.substring(selection.end));
      }
      setText(buffer.toString());
      final previousLength = selection.end - selection.start;
      _selection = selection.copyWith(
          baseOffset: selection.baseOffset + text.length - previousLength,
          extentOffset: selection.extentOffset + text.length - previousLength);
      _controller.selection = _selection;
    }
  }

  void _formatWithFont(UnicodeFont font) {
    _currentFont = font;
    final selection = _selection;
    if (selection.isCollapsed) {
      if (!_focusNode.hasFocus) {
        _addPostFrameCallback(() {
          _ignoreUpdateCall = true;
          _controller.selection = selection;
          _currentFont = font;
          _notifyFontChanged(font);
        });
      }
      return;
    } else {
      // print('_format with font $font and selection $selection...');
      final text = _controller.text;
      final selectedText = selection.textInside(text);
      // print(
      //     'selection: ${selection.baseOffset}-${selection.extentOffset}, selectedText=$selectedText');
      final detectedFont = UnicodeFontConverter.getFont(selectedText);
      // print('detectedFont: $detectedFont');
      String update;
      if (detectedFont != UnicodeFont.normal) {
        update = UnicodeFontConverter.clear(selectedText);
        if (detectedFont != font) {
          // apply the new font
          update = UnicodeFontConverter.encode(update, font);
        }
      } else {
        update = UnicodeFontConverter.encode(selectedText, font);
      }
      final buffer = StringBuffer();
      if (selection.start > 0) {
        buffer.write(text.substring(0, selection.start));
      }
      buffer.write(update);
      if (selection.end < text.length && selection.end > 0) {
        buffer.write(text.substring(selection.end));
      }
      final resultText = buffer.toString();
      // print('_formatL result: $resultText');
      setText(resultText);
      _addPostFrameCallback(() {
        final originalSelectionLength = selectedText.length;
        final updatedSelectionLength = update.length;
        final diff = updatedSelectionLength - originalSelectionLength;
        if (diff == 0) {
          _controller.selection = selection;
        } else {
          final extentOffset = selection.extentOffset + diff;
          final baseOffset = selection.extentOffset + diff;
          final newSelection = selection.affinity == TextAffinity.upstream
              ? selection.copyWith(
                  baseOffset: baseOffset, extentOffset: extentOffset)
              : selection.copyWith(extentOffset: extentOffset);
          _selection = newSelection;
          _controller.selection = newSelection;
        }
      });

      // _controller.selection = selection;
      // _focusNode.requestFocus();
    }
  }

  void _addPostFrameCallback(void Function() callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Retrieves the edited text as HTML
  ///
  /// Compare [getFullHtml()] to the complete HTML document's text.
  String getText() {
    return _controller.text;
  }

  /// Retrieves the currently selected text.
  String? getSelectedText() {
    return (_controller.selection.isCollapsed)
        ? null
        : _controller.selection.textInside(_controller.text);
  }

  String storeSelectionRange() {
    _selection = _controller.selection;
    return _selection.textInside(_controller.text);
  }

  void restoreSelectionRange() {
    _controller.selection = _selection;
  }

  /// Replaces all text parts [from] with the replacement [replace] and returns the updated text.
  String replaceAll(String from, String replace) {
    final text = (getText()).replaceAll(from, replace);
    setText(text);
    return text;
  }

  /// Sets the given text, replacing the previous text completely
  void setText(String text) {
    _previousText = text;
    _controller.text = text;
  }

  void dispose() {
    _controller.removeListener(_onUpdated);
    _focusNode.removeListener(_onFocusChanged);
  }

  void _notifyFontChanged(UnicodeFont font) {
    _currentFont = font;
    for (final callback in _fontListeners) {
      callback(font);
    }
  }
}
