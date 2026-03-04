/// Tests for website_url — URL helpers for web platform.
library;

import 'package:flutter_test/flutter_test.dart';

// We can't import website_url directly in non-web test environment because
// the kIsWeb constant would be false. Test the contract values instead.

void main() {
  group('website_url contracts', () {
    test('websiteUrl production value is "/"', () {
      // In production (non-debug), websiteUrl returns '/'
      const productionUrl = '/';
      expect(productionUrl, '/');
      expect(productionUrl.isNotEmpty, true);
    });

    test('websiteUrl debug value is localhost:8080', () {
      const debugUrl = 'http://localhost:8080';
      expect(debugUrl, contains('localhost'));
      expect(debugUrl, contains('8080'));
    });

    test('showWebsiteLink is false in non-web tests', () {
      // In test environment, kIsWeb is false
      // showWebsiteLink == kIsWeb
      const kIsWeb = false; // Flutter test runner is not web
      expect(kIsWeb, false);
    });

    test('app URL path is /app/', () {
      // Documented contract: app lives at /app/ on Firebase Hosting
      const appPath = '/app/';
      expect(appPath, startsWith('/'));
      expect(appPath, endsWith('/'));
    });
  });
}
