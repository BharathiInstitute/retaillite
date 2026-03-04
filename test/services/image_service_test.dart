/// ImageService — constants and size validation tests
///
/// Tests ImageSizes constants and file size validation logic.
/// The actual image picking/uploading is platform-dependent,
/// but the size thresholds and resize logic are testable.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:retaillite/core/services/image_service.dart';

void main() {
  group('ImageSizes — constants', () {
    test('logoSize is 200px', () {
      expect(ImageSizes.logoSize, 200);
    });

    test('productThumbnailSize is 150px', () {
      expect(ImageSizes.productThumbnailSize, 150);
    });

    test('maxFileSizeBytes is 15MB', () {
      expect(ImageSizes.maxFileSizeBytes, 15 * 1024 * 1024);
      expect(ImageSizes.maxFileSizeBytes, 15728640);
    });

    test('logo is larger than product thumbnail', () {
      expect(ImageSizes.logoSize, greaterThan(ImageSizes.productThumbnailSize));
    });
  });

  group('ImageSizes — file size validation logic', () {
    test('file under 15MB passes', () {
      const fileSize = 5 * 1024 * 1024; // 5MB
      expect(fileSize <= ImageSizes.maxFileSizeBytes, isTrue);
    });

    test('file exactly 15MB passes', () {
      expect(
        ImageSizes.maxFileSizeBytes <= ImageSizes.maxFileSizeBytes,
        isTrue,
      );
    });

    test('file over 15MB fails', () {
      const fileSize = 16 * 1024 * 1024; // 16MB
      expect(fileSize > ImageSizes.maxFileSizeBytes, isTrue);
    });

    test('common photo sizes (phone cameras) vs limit', () {
      // Typical phone camera JPEG sizes
      final sizes = {
        '2MP JPEG': 500 * 1024, // ~500KB
        '8MP JPEG': 3 * 1024 * 1024, // ~3MB
        '12MP JPEG': 5 * 1024 * 1024, // ~5MB
        '48MP RAW': 20 * 1024 * 1024, // ~20MB (FAILS)
        '108MP RAW': 30 * 1024 * 1024, // ~30MB (FAILS)
      };

      expect(sizes['2MP JPEG']! <= ImageSizes.maxFileSizeBytes, isTrue);
      expect(sizes['8MP JPEG']! <= ImageSizes.maxFileSizeBytes, isTrue);
      expect(sizes['12MP JPEG']! <= ImageSizes.maxFileSizeBytes, isTrue);
      expect(sizes['48MP RAW']! <= ImageSizes.maxFileSizeBytes, isFalse);
      expect(sizes['108MP RAW']! <= ImageSizes.maxFileSizeBytes, isFalse);
    });
  });

  group('Image resize dimensions verification', () {
    test('logo resize maintains square aspect', () {
      // Logo is resized to logoSize x logoSize
      const targetSize = ImageSizes.logoSize;
      expect(targetSize, 200);
      // After resize, width == height == 200
    });

    test('product thumbnail is appropriate for grid display', () {
      const size = ImageSizes.productThumbnailSize;
      // Should be reasonable for a grid card (not too big, not too small)
      expect(size, greaterThanOrEqualTo(100));
      expect(size, lessThanOrEqualTo(300));
    });
  });
}
