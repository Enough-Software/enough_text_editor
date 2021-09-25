import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:flutter/material.dart';

import 'base.dart';
import 'package:enough_ascii_art/enough_ascii_art.dart';

/// Controls the font family name of the current / selected text.
///
/// This widget depends on a [TextEditorApiWidget] in the widget tree.
class FontFamilyDropdown extends StatefulWidget {
  const FontFamilyDropdown({Key? key}) : super(key: key);

  @override
  _FontFamilyDropdownState createState() => _FontFamilyDropdownState();
}

class _FontFamilyDropdownState extends State<FontFamilyDropdown> {
  UnicodeFont? currentFont;

  void _onFontChanged(UnicodeFont? font) {
    setState(() {
      currentFont = font;
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = TextEditorApiWidget.of(context)!.editorApi;
    api.addFontListener(_onFontChanged);
    const selectedTextStyle = TextStyle(fontSize: 12);
    return PlatformDropdownButton<UnicodeFont>(
      value: currentFont,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            currentFont = value;
          });
          api.setFont(value);
        }
      },
      selectedItemBuilder: (context) => UnicodeFont.values
          .map(
            (font) => Center(
              child: SizedBox(
                width: 60,
                child: Text(
                  font.encodedName,
                  style: selectedTextStyle,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.right,
                  softWrap: false,
                ),
              ),
            ),
          )
          .toList(),
      items: UnicodeFont.values
          .map(
            (font) => DropdownMenuItem<UnicodeFont>(
              child: Text(font.encodedName),
              value: font,
            ),
          )
          .toList(),
    );
  }
}
