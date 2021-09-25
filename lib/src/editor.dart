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
                child: PlatformMaterial(
                  elevation: 8.0,
                  color: PlatformInfo.isCupertino
                      ? CupertinoTheme.of(context).barBackgroundColor
                      : Theme.of(context).canvasColor,
                  child: UnicodeFontSelector(onSelected: callback),
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
      //TODO
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

class _CupertinoTextSelectionControls extends CupertinoTextSelectionControls {
  final List<PlatformTextSelectionItem> customEntries;
  final bool includeStandardEntries;
  _CupertinoTextSelectionControls(
      {this.includeStandardEntries = true, required this.customEntries});
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
