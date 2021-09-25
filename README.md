<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

An API-based plain text editor for Flutter that support unicode text formatting.

## Features

* Supports to be used in any scenarios: 
  - with editor chrome: The `PackagedTextEditor` includes additional chrome for choosing bold, italic, underline or strike through text as well as selecting an unicode font.
  - without editor chrome: The `TextEditor` still has all the editing options but integrated in the text selection overlay menu.
  - with a separate chrome from the editor: `SliverHeaderTextEditorControls` along with `TextEditor`, to be used in a `CustomScrollView` with a sticky editor chrome.
  - in any custom scenario: as the `TextEditor` is API based you can create your own chrome or extend it easily, for example by defining your own overlay menu items.

## Getting started

Add the dependency to `enough_text_editor` in your _pubspec.yaml_ file:
```yaml
# (to be done after releasing this package to pub.dev)
```

## Usage

With editor chrome / single line mode:
```dart
PackagedTextEditor(
    isSingleLine: true,
    showClearOption: true,
    onCreated: (api) {
        _editorApi = api;
    },
    initialContent:
    '''Hello world, this is an example text for you to edit!''',
);
```

With editor chrome / multiple lines mode:
```dart
PackagedTextEditor(
    isSingleLine: false,
    minLines: 3,
    onCreated: (api) {
        _editorApi = api;
    },
    initialContent:
    '''Hello world, this is an example text for you to edit!''',
);
```

Without editor chrome:
```dart
TextEditor(
    isSingleLine: true,
    label: const Text('Subject'),
    onCreated: (api) {
        _editorApi = api;
    },
    initialContent:
    '''My subject''',
);
```




## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
