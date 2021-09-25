import 'dart:math';

import 'package:enough_ascii_art/enough_ascii_art.dart';
import 'package:enough_platform_widgets/enough_platform_widgets.dart';
import 'package:enough_platform_widgets/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'editor_api.dart';
import 'package:flutter/widgets.dart';

import 'models.dart';

/// Slim, API-based text editor
class TextEditor extends StatefulWidget {
  /// Set the [initialContent] to populate the editor with some existing text
  final String initialContent;

  /// Define the `onCreated(EditorApi)` callback to get notified when the API is ready.
  final void Function(TextEditorApi)? onCreated;

  /// Defines if the default text selection menu items `𝗕` (bold), `𝑰` (italic), `U̲` (underlined),`T̶` (strikethrough) should be added - defaults to `true`.
  final bool addEditorSelectionMenuItems;

  /// Defines if the system text selection menu items like copy & paste should be added - defaults to `true`.
  final bool addSystemSelectionMenuItems;

  /// List of custom text selection / context menu items.
  final List<TextSelectionMenuItem>? textSelectionMenuItems;

  /// Is this editor limited to a single line?
  final bool isSingleLine;

  /// The minimum shown lines
  final int? minLines;

  /// Should this widget automatically adapt it's height?
  final bool expands;

  /// Should the editor show a clear option?
  final bool showClearOption;

  /// The fonts symbol in the default editor seleciton menu items, defaults to `🖋️`
  final String fontSymbol;

  /// Label of this editor
  final Widget? label;

  /// Creates a new text editor
  ///
  /// Set the [initialContent] to populate the editor with some existing text
  /// Set [expands] to let the editor set its height automatically - by default this is `true`.
  /// Specify the [minHeight] to set a different height than the default `100` pixel.
  /// Define the [onCreated] `onCreated(EditorApi)` callback to get notified when the API is ready.
  /// Set [splitBlockquotes] to `false` in case block quotes should not be split when the user adds a newline in one - this defaults to `true`.
  /// Set [addSystemtSelectionMenuItems] to `false` when you do not want to have the default text selection items enabled.
  /// Set [addEditorSelectionMenuItems] to `false` when you do not want to have the default text selection items enabled.
  /// You can define your own custom context / text selection menu entries using [textSelectionMenuItems].
  const TextEditor({
    Key? key,
    this.initialContent = '',
    this.onCreated,
    this.addEditorSelectionMenuItems = true,
    this.addSystemSelectionMenuItems = true,
    this.textSelectionMenuItems,
    this.isSingleLine = true,
    this.expands = false,
    this.minLines,
    this.fontSymbol = '🖋️',
    this.showClearOption = true,
    this.label,
  }) : super(key: key);

  @override
  TextEditorState createState() => TextEditorState();
}

/// You can access the API by accessing the HtmlEditor's state.
/// The editor state can be accessed directly when using a GlobalKey<HtmlEditorState>.
class TextEditorState extends State<TextEditor> {
  late TextEditingController _textEditingController;
  late TextEditorApi _api;
  late FocusNode _focusNode;

  /// Access to the API of the editor.
  ///
  /// Instead of accessing the API via the `HtmlEditorState` you can also directly get in in the `HtmlEditor.onCreated(...)` callback.
  TextEditorApi get api => _api;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textEditingController = TextEditingController(text: widget.initialContent);
    _api = TextEditorApi(this, _textEditingController, _focusNode);
    final callback = widget.onCreated;
    if (callback != null) {
      SchedulerBinding.instance?.addPostFrameCallback((_) => callback(_api));
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //   if (widget.expands && !widget.isSingleLine) {
    //     final size = MediaQuery.of(context).size;
    //     return SizedBox(
    //       height: _documentHeight ?? size.height,
    //       width: size.width,
    //       child: _buildEditor(),
    //     );
    //   } else {
    //     return _buildEditor();
    //   }
    // }

    // Widget _buildEditor() {
    // final theme = Theme.of(context);
    // final isDark = (theme.brightness == Brightness.dark);
    final textSelectionMenuItems = widget.textSelectionMenuItems ?? [];
    final api = _api;

    return DecoratedPlatformTextField(
      key: ValueKey(widget.initialContent),
      controller: _textEditingController,
      focusNode: _focusNode,
      maxLines: widget.isSingleLine ? 1 : null,
      minLines: widget.minLines,
      expands: widget.expands,
      decoration: buildInputDecoration(context),
      cupertinoAlignLabelOnTop: true,
      cupertinoSuffixMode: OverlayVisibilityMode.editing,
      selectionControls: PlatformTextSelectionControls.create(
        includeSystemEntries: widget.addSystemSelectionMenuItems,
        customEntries: [
          if (widget.addEditorSelectionMenuItems) ...{
            PlatformTextSelectionItem('𝗕', (delegate) => api.formatBold()),
            PlatformTextSelectionItem('𝑰', (delegate) => api.formatItalic()),
            PlatformTextSelectionItem(
                'U̲', (delegate) => api.formatUnderline()),
            PlatformTextSelectionItem(
                'T̶', (delegate) => api.formatStrikeThrough()),
            PlatformTextSelectionItem(
              widget.fontSymbol,
              (delegate) {
                delegate.hideToolbar(false);
                FontSelector.show(context: context, api: api);
              },
            ),
            PlatformTextSelectionItem(
                '✕', (delegate) => delegate.hideToolbar(false)),
          },
          for (final item in textSelectionMenuItems) ...{
            PlatformTextSelectionItem(
                item.label, (delegate) => item.action(_api)),
          }
        ],
      ),
    );
  }

  InputDecoration? buildInputDecoration(BuildContext context) {
    final label = widget.label;
    final showClearOption = widget.showClearOption;
    if (label == null && !showClearOption) {
      return null;
    }
    return InputDecoration(
      label: label,
      suffix: showClearOption
          ? (PlatformInfo.isCupertino
              ? CupertinoButton(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 5, 2),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 20.0,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  onPressed: () => _textEditingController.text = '',
                )
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _textEditingController.text = '',
                ))
          : null,
    );
  }
}

class FontSelector {
  static OverlayEntry? _current;

  static void show({
    required BuildContext context,
    required TextEditorApi api,
  }) {
    // a dialog closes the keyboard, which is not wanted, so instead an overlay is used.
    //   await DialogHelper.showWidgetDialog(context,
    //       UnicodeFontSelector(onSelected: (font) {
    //     api.setFont(font);
    //     Navigator.of(context).pop();
    //   }));
    // }
    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }
    final existing = _current;
    if (existing != null) {
      _current = null;
      existing.remove();
      return;
    }
    // ignore: prefer_function_declarations_over_variables
    final handler = (UnicodeFont? font) {
      final entry = _current;
      if (entry != null) {
        _current = null;
        entry.remove();
      }
      if (font != null) {
        api.setFont(font);
      }
    };
    final entry = buildOverlayEntry(context, handler);
    _current = entry;
    overlay.insert(entry);
  }

  static OverlayEntry buildOverlayEntry(
      BuildContext context, Function(UnicodeFont? font) callback) {
    final viewInsets = EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance!.window.viewInsets,
        WidgetsBinding.instance!.window.devicePixelRatio);
    final size = MediaQuery.of(context).size;
    const horizontalPadding = 40.0;
    const verticalPadding = 10.0;
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => callback(null),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0x09000000))),
            Positioned(
              left: viewInsets.left + horizontalPadding,
              top: viewInsets.top + verticalPadding,
              width: min(size.width - 2 * horizontalPadding, 200.0),
              bottom: viewInsets.bottom - verticalPadding,
              child: SingleChildScrollView(
                child: SafeArea(
                  child: PlatformMaterial(
                    elevation: 8.0,
                    color: PlatformInfo.isCupertino
                        ? CupertinoTheme.of(context).barBackgroundColor
                        : Theme.of(context).canvasColor,
                    child: UnicodeFontSelector(onSelected: callback),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnicodeFontSelector extends StatelessWidget {
  final void Function(UnicodeFont font) onSelected;
  const UnicodeFontSelector({
    Key? key,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: UnicodeFont.values
            .map(
              (font) => PlatformListTile(
                title: Text(font.encodedName),
                onTap: () => onSelected(font),
              ),
            )
            .toList(),
      ),
    );
  }
}

class PlatformMaterial extends StatelessWidget {
  const PlatformMaterial({
    Key? key,
    this.widgetKey,
    this.type = MaterialType.canvas,
    this.elevation = 0.0,
    this.color,
    this.shadowColor,
    this.textStyle,
    this.borderRadius,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.none,
    this.animationDuration = kThemeChangeDuration,
    this.child,
  }) : super(key: key);

  final Key? widgetKey;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  /// The kind of material to show (e.g., card or canvas). This
  /// affects the shape of the widget, the roundness of its corners if
  /// the shape is rectangular, and the default color.
  final MaterialType type;

  /// {@template flutter.material.material.elevation}
  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material and the opacity
  /// of the elevation overlay color if it is applied.
  ///
  /// If this is non-zero, the contents of the material are clipped, because the
  /// widget conceptually defines an independent printed piece of material.
  ///
  /// Defaults to 0. Changing this value will cause the shadow and the elevation
  /// overlay to animate over [Material.animationDuration].
  ///
  /// The value is non-negative.
  ///
  /// See also:
  ///
  ///  * [ThemeData.applyElevationOverlayColor] which controls the whether
  ///    an overlay color will be applied to indicate elevation.
  ///  * [Material.color] which may have an elevation overlay applied.
  ///
  /// {@endtemplate}
  final double elevation;

  /// The color to paint the material.
  ///
  /// Must be opaque. To create a transparent piece of material, use
  /// [MaterialType.transparency].
  ///
  /// To support dark themes, if the surrounding
  /// [ThemeData.applyElevationOverlayColor] is true and [ThemeData.brightness]
  /// is [Brightness.dark] then a semi-transparent overlay color will be
  /// composited on top of this color to indicate the elevation.
  ///
  /// By default, the color is derived from the [type] of material.
  final Color? color;

  /// The color to paint the shadow below the material.
  ///
  /// If null, [ThemeData.shadowColor] is used, which defaults to fully opaque black.
  ///
  /// Shadows can be difficult to see in a dark theme, so the elevation of a
  /// surface should be portrayed with an "overlay" in addition to the shadow.
  /// As the elevation of the component increases, the overlay increases in
  /// opacity.
  ///
  /// See also:
  ///
  ///  * [ThemeData.applyElevationOverlayColor], which turns elevation overlay
  /// on or off for dark themes.
  final Color? shadowColor;

  /// The typographical style to use for text within this material.
  final TextStyle? textStyle;

  /// Defines the material's shape as well its shadow.
  ///
  /// If shape is non null, the [borderRadius] is ignored and the material's
  /// clip boundary and shadow are defined by the shape.
  ///
  /// A shadow is only displayed if the [elevation] is greater than
  /// zero.
  final ShapeBorder? shape;

  /// Whether to paint the [shape] border in front of the [child].
  ///
  /// The default value is true.
  /// If false, the border will be painted behind the [child].
  final bool borderOnForeground;

  /// {@template flutter.material.Material.clipBehavior}
  /// The content will be clipped (or not) according to this option.
  ///
  /// See the enum [Clip] for details of all possible options and their common
  /// use cases.
  /// {@endtemplate}
  ///
  /// Defaults to [Clip.none], and must not be null.
  final Clip clipBehavior;

  /// Defines the duration of animated changes for [shape], [elevation],
  /// [shadowColor] and the elevation overlay if it is applied.
  ///
  /// The default value is [kThemeChangeDuration].
  final Duration animationDuration;

  /// If non-null, the corners of this box are rounded by this
  /// [BorderRadiusGeometry] value.
  ///
  /// Otherwise, the corners specified for the current [type] of material are
  /// used.
  ///
  /// If [shape] is non null then the border radius is ignored.
  ///
  /// Must be null if [type] is [MaterialType.circle].
  final BorderRadiusGeometry? borderRadius;
  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (context, platform) => Material(
        key: widgetKey,
        child: child,
        color: color,
        shadowColor: shadowColor,
        elevation: elevation,
        animationDuration: animationDuration,
        borderOnForeground: borderOnForeground,
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        shape: shape,
        textStyle: textStyle,
        type: type,
      ),
      cupertino: (context, platform) => CupertinoBar(
        child: child ?? Container(),
        blurBackground: true,
      ),
    );
  }
}

class PlatformTextSelectionItem {
  final String text;
  final void Function(TextSelectionDelegate delegate) onPressed;

  const PlatformTextSelectionItem(this.text, this.onPressed);
}

class PlatformTextSelectionControls {
  static TextSelectionControls create(
      {bool includeSystemEntries = true,
      required List<PlatformTextSelectionItem> customEntries}) {
    if (PlatformInfo.isCupertino) {
      return _CupertinoTextSelectionControls(
        includeStandardEntries: includeSystemEntries,
        customEntries: customEntries,
      );
    }
    return _MaterialTextSelectionControls(
      includeStandardEntries: includeSystemEntries,
      customEntries: customEntries,
    );
  }
}

class _TextSelectionToolbarItemData {
  const _TextSelectionToolbarItemData({
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;
}

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleOverlap = 1.5;
// Extracted from https://developer.apple.com/design/resources/.
const double _kSelectionHandleRadius = 6;

// Minimal padding from tip of the selection toolbar arrow to horizontal edges of the
// screen. Eyeballed value.
const double _kArrowScreenPadding = 26.0;

class _CupertinoTextSelectionControls extends TextSelectionControls {
  final List<PlatformTextSelectionItem> customEntries;
  final bool includeStandardEntries;
  _CupertinoTextSelectionControls(
      {this.includeStandardEntries = true, required this.customEntries});

  /// Returns the size of the Cupertino handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _CupertinoTextSelectionControlsToolbar(
      clipboardStatus: clipboardStatus,
      endpoints: endpoints,
      globalEditableRegion: globalEditableRegion,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      selectionMidpoint: selectionMidpoint,
      textLineHeight: textLineHeight,
      customEntries: customEntries,
      customHandler: (item) => item.onPressed(delegate),
      includeStandardEntries: includeStandardEntries,
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textLineHeight,
      [VoidCallback? onTap, double? startGlyphHeight, double? endGlyphHeight]) {
    // iOS selection handles do not respond to taps.

    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    startGlyphHeight = startGlyphHeight ?? textLineHeight;
    endGlyphHeight = endGlyphHeight ?? textLineHeight;

    final Size desiredSize;
    final Widget handle;

    final Widget customPaint = CustomPaint(
      painter: _CupertinoTextSelectionHandlePainter(
          CupertinoTheme.of(context).primaryColor),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        desiredSize = getHandleSize(startGlyphHeight);
        handle = SizedBox.fromSize(
          size: desiredSize,
          child: customPaint,
        );
        return handle;
      case TextSelectionHandleType.right:
        desiredSize = getHandleSize(endGlyphHeight);
        handle = SizedBox.fromSize(
          size: desiredSize,
          child: customPaint,
        );
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight,
      [double? startGlyphHeight, double? endGlyphHeight]) {
    startGlyphHeight = startGlyphHeight ?? textLineHeight;
    endGlyphHeight = endGlyphHeight ?? textLineHeight;

    final Size handleSize;

    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        handleSize = getHandleSize(startGlyphHeight);
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        handleSize = getHandleSize(endGlyphHeight);
        return Offset(
          handleSize.width / 2,
          handleSize.height -
              2 * _kSelectionHandleRadius +
              _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      case TextSelectionHandleType.collapsed:
        handleSize = getHandleSize(textLineHeight);
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

/// Draws a single text selection handle with a bar and a ball.
class _CupertinoTextSelectionHandlePainter extends CustomPainter {
  const _CupertinoTextSelectionHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double halfStrokeWidth = 1.0;
    final Paint paint = Paint()..color = color;
    final Rect circle = Rect.fromCircle(
      center: const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      radius: _kSelectionHandleRadius,
    );
    final Rect line = Rect.fromPoints(
      const Offset(
        _kSelectionHandleRadius - halfStrokeWidth,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(_kSelectionHandleRadius + halfStrokeWidth, size.height),
    );
    final Path path = Path()
      ..addOval(circle)
      // Draw line so it slightly overlaps the circle.
      ..addRect(line);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CupertinoTextSelectionHandlePainter oldPainter) =>
      color != oldPainter.color;
}

// Generates the child that's passed into CupertinoTextSelectionToolbar.
class _CupertinoTextSelectionControlsToolbar extends StatefulWidget {
  const _CupertinoTextSelectionControlsToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
    required this.customEntries,
    required this.customHandler,
    required this.includeStandardEntries,
  }) : super(key: key);

  final ClipboardStatusNotifier? clipboardStatus;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset selectionMidpoint;
  final double textLineHeight;
  final List<PlatformTextSelectionItem> customEntries;
  final void Function(PlatformTextSelectionItem item) customHandler;
  final bool includeStandardEntries;

  @override
  _CupertinoTextSelectionControlsToolbarState createState() =>
      _CupertinoTextSelectionControlsToolbarState();
}

class _CupertinoTextSelectionControlsToolbarState
    extends State<_CupertinoTextSelectionControlsToolbar> {
  ClipboardStatusNotifier? _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.handlePaste != null) {
      _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      _clipboardStatus!.update();
    }
  }

  @override
  void didUpdateWidget(_CupertinoTextSelectionControlsToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus != widget.clipboardStatus) {
      if (_clipboardStatus != null) {
        _clipboardStatus!.removeListener(_onChangedClipboardStatus);
        _clipboardStatus!.dispose();
      }
      _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
      _clipboardStatus!.addListener(_onChangedClipboardStatus);
      if (widget.handlePaste != null) {
        _clipboardStatus!.update();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (_clipboardStatus != null && !_clipboardStatus!.disposed) {
      _clipboardStatus!.removeListener(_onChangedClipboardStatus);
      if (widget.clipboardStatus == null) {
        _clipboardStatus!.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null &&
        _clipboardStatus!.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it, assuming there's always enough
    // space at the bottom in this case.
    final double anchorX =
        (widget.selectionMidpoint.dx + widget.globalEditableRegion.left).clamp(
      _kArrowScreenPadding + mediaQuery.padding.left,
      mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
    );

    // The y-coordinate has to be calculated instead of directly quoting
    // selectionMidpoint.dy, since the caller
    // (TextSelectionOverlay._buildToolbar) does not know whether the toolbar is
    // going to be facing up or down.
    final Offset anchorAbove = Offset(
      anchorX,
      widget.endpoints.first.point.dy -
          widget.textLineHeight +
          widget.globalEditableRegion.top,
    );
    final Offset anchorBelow = Offset(
      anchorX,
      widget.endpoints.last.point.dy + widget.globalEditableRegion.top,
    );

    final List<Widget> items = <Widget>[];
    final CupertinoLocalizations localizations =
        CupertinoLocalizations.of(context);
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      items.add(CupertinoTextSelectionToolbarButton.text(
        onPressed: onPressed,
        text: text,
      ));
    }

    if (widget.includeStandardEntries) {
      if (widget.handleCut != null) {
        addToolbarButton(localizations.cutButtonLabel, widget.handleCut!);
      }
      if (widget.handleCopy != null) {
        addToolbarButton(localizations.copyButtonLabel, widget.handleCopy!);
      }
      if (widget.handlePaste != null &&
          _clipboardStatus!.value == ClipboardStatus.pasteable) {
        addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste!);
      }
      if (widget.handleSelectAll != null) {
        addToolbarButton(
            localizations.selectAllButtonLabel, widget.handleSelectAll!);
      }
    }
    for (final entry in widget.customEntries) {
      addToolbarButton(entry.text, () => widget.customHandler(entry));
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return CupertinoTextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: items,
    );
  }
}

class _MaterialTextSelectionControls extends MaterialTextSelectionControls {
  // Padding between the toolbar and the anchor.
  static const double _kToolbarContentDistanceBelow = 20.0;
  static const double _kToolbarContentDistance = 8.0;

  final List<PlatformTextSelectionItem> customEntries;
  final bool includeStandardEntries;
  _MaterialTextSelectionControls(
      {this.includeStandardEntries = true, required this.customEntries});

  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // super.buildToolbar(context, globalEditableRegion, textLineHeight, selectionMidpoint, endpoints, delegate, clipboardStatus, lastSecondaryTapDownPosition)
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        endpoints.length > 1 ? endpoints[1] : endpoints[0];
    final Offset anchorAbove = Offset(
        globalEditableRegion.left + selectionMidpoint.dx,
        globalEditableRegion.top +
            startTextSelectionPoint.point.dy -
            textLineHeight -
            _kToolbarContentDistance);
    final Offset anchorBelow = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top +
          endTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    return _MaterialTextSelectionToolbar(
      handler: (item) => item.onPressed(delegate),
      includeStandardEntries: includeStandardEntries,
      customEntries: customEntries,
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      clipboardStatus: clipboardStatus,
      handleCopy: canCopy(delegate)
          ? () => handleCopy(delegate, clipboardStatus)
          : null,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
    );
  }
}

class _MaterialTextSelectionToolbar extends StatefulWidget {
  const _MaterialTextSelectionToolbar({
    Key? key,
    required this.handler,
    this.includeStandardEntries = true,
    required this.customEntries,
    required this.anchorAbove,
    required this.anchorBelow,
    required this.clipboardStatus,
    this.handleCopy,
    // this.handleCustomButton,
    this.handleCut,
    this.handlePaste,
    this.handleSelectAll,
  }) : super(key: key);

  final List<PlatformTextSelectionItem> customEntries;
  final bool includeStandardEntries;
  final void Function(PlatformTextSelectionItem item) handler;
  final Offset anchorAbove;
  final Offset anchorBelow;
  final ClipboardStatusNotifier clipboardStatus;
  final VoidCallback? handleCopy;
  final VoidCallback? handleCut;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;

  @override
  _MaterialTextSelectionToolbarState createState() =>
      _MaterialTextSelectionToolbarState();
}

class _MaterialTextSelectionToolbarState
    extends State<_MaterialTextSelectionToolbar> {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus.addListener(_onChangedClipboardStatus);
    widget.clipboardStatus.update();
  }

  @override
  void didUpdateWidget(_MaterialTextSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
    widget.clipboardStatus.update();
  }

  @override
  void dispose() {
    super.dispose();
    if (!widget.clipboardStatus.disposed) {
      widget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    final itemDatas = [
      if (widget.includeStandardEntries) ...{
        if (widget.handleCut != null)
          _TextSelectionToolbarItemData(
            label: localizations.cutButtonLabel,
            onPressed: widget.handleCut,
          ),
        if (widget.handleCopy != null)
          _TextSelectionToolbarItemData(
            label: localizations.copyButtonLabel,
            onPressed: widget.handleCopy,
          ),
        if (widget.handlePaste != null &&
            widget.clipboardStatus.value == ClipboardStatus.pasteable)
          _TextSelectionToolbarItemData(
            label: localizations.pasteButtonLabel,
            onPressed: widget.handlePaste,
          ),
        if (widget.handleSelectAll != null)
          _TextSelectionToolbarItemData(
            label: localizations.selectAllButtonLabel,
            onPressed: widget.handleSelectAll,
          ),
      },
      for (final entry in widget.customEntries) ...{
        _TextSelectionToolbarItemData(
          onPressed: () => widget.handler(entry),
          label: entry.text,
        ),
      },
    ];

    int childIndex = 0;
    return TextSelectionToolbar(
      anchorAbove: widget.anchorAbove,
      anchorBelow: widget.anchorBelow,
      children: itemDatas.map((_TextSelectionToolbarItemData itemData) {
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(
            childIndex++,
            itemDatas.length,
          ),
          onPressed: itemData.onPressed,
          child: Text(
            itemData.label,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.right,
            softWrap: false,
          ),
        );
      }).toList(),
    );
  }
}
