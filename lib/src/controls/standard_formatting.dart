import 'package:enough_ascii_art/enough_ascii_art.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:enough_text_editor/enough_text_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'base.dart';

/// Controls the base format settings bold, italic, underlined and strike through
///
/// This widget depends on a [TextEditorApiWidget] in the widget tree.
class BaseFormatButtons extends StatefulWidget {
  const BaseFormatButtons({Key? key}) : super(key: key);

  @override
  _BaseFormatButtonsState createState() => _BaseFormatButtonsState();
}

class _BaseFormatButtonsState extends State<BaseFormatButtons> {
  final _isSelected = [false, false, false, false];

  void _onFontChanged(UnicodeFont font) {
    if (mounted) {
      setState(() {
        _isSelected[0] = font.isBold;
        _isSelected[1] = font.isItalic;
        _isSelected[2] = font.isUnderlined;
        _isSelected[3] = font.isStrikeThrough;
      });
    }
  }

  @override
  void dispose() {
    final api = TextEditorApiWidget.of(context)?.editorApi;
    api?.removeFontListener(_onFontChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = TextEditorApiWidget.of(context)!.editorApi;
    api.addFontListener(_onFontChanged);

    return PlatformToggleButtons(
      children: [
        Icon(CommonPlatformIcons.bold),
        Icon(CommonPlatformIcons.italic),
        Icon(CommonPlatformIcons.underlined),
        Icon(CommonPlatformIcons.strikethrough),
      ],
      onPressed: (int index) {
        switch (index) {
          case 0:
            api.formatBold();
            break;
          case 1:
            api.formatItalic();
            break;
          case 2:
            api.formatUnderline();
            break;
          case 3:
            api.formatStrikeThrough();
            break;
        }
        setState(() {
          _isSelected[index] = !_isSelected[index];
        });
      },
      isSelected: _isSelected,
      cupertinoPadding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}
