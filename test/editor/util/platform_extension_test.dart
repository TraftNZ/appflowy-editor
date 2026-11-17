import 'dart:io';

import 'package:appflowy_editor/src/editor/util/platform_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'navigator_platform_stub.dart'
    if (dart.library.js_interop) 'navigator_platform_web.dart';

void main() {
  group('platform extension', () {
    test('test safe platform judgement', () {
      if (!kIsWeb && Platform.isLinux) {
        expect(PlatformExtension.isLinux, true);
        expect(PlatformExtension.isWebOnLinux, false);
      }

      if (!kIsWeb && Platform.isWindows) {
        expect(PlatformExtension.isWindows, true);
        expect(PlatformExtension.isWebOnWindows, false);
      }

      if (!kIsWeb && Platform.isMacOS) {
        expect(PlatformExtension.isMacOS, true);
        expect(PlatformExtension.isWebOnMacOS, false);
      }
    });

    test('web host OS comes from the browser navigator', () {
      if (!kIsWeb) {
        expect(PlatformExtension.isWebOnLinux, false);
        expect(PlatformExtension.isWebOnMacOS, false);
        expect(PlatformExtension.isWebOnWindows, false);
        return;
      }
      final platform = navigatorPlatform.toLowerCase();
      expect(platform, isNotEmpty);
      expect(PlatformExtension.isWebOnLinux, platform.contains('linux'));
      expect(PlatformExtension.isWebOnMacOS, platform.contains('mac'));
      expect(PlatformExtension.isWebOnWindows, platform.contains('windows'));
    });
  });
}
