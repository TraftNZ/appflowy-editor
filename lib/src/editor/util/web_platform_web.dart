import 'package:web/web.dart' as web;

/// The browser's `navigator.platform`, lower-cased.
String get webNavigatorPlatform => web.window.navigator.platform.toLowerCase();
