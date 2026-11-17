import 'package:web/web.dart' as web;

/// Test-side view of the browser's `navigator.platform`.
String get navigatorPlatform => web.window.navigator.platform;
