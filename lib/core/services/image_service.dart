/// Image service for picking and resizing images
/// Automatically resizes mobile photos to save storage
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Image sizes for different use cases
class ImageSizes {
  static const int logoSize = 200;
  static const int productThumbnailSize = 150;
}

/// Service for picking and resizing images
class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick and resize image for shop logo (200x200)
  static Future<String?> pickAndResizeLogo() async {
    return _pickAndResize(
      size: ImageSizes.logoSize,
      subfolder: 'logos',
      prefix: 'shop_logo',
    );
  }

  /// Pick and resize image for product thumbnail (150x150)
  static Future<String?> pickAndResizeProductImage(String productId) async {
    return _pickAndResize(
      size: ImageSizes.productThumbnailSize,
      subfolder: 'products',
      prefix: 'product_$productId',
    );
  }

  /// Pick image from gallery and resize
  static Future<String?> _pickAndResize({
    required int size,
    required String subfolder,
    required String prefix,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Read the image bytes
      final Uint8List bytes = await pickedFile.readAsBytes();

      // Resize in isolate to avoid blocking UI
      final Uint8List resizedBytes = await compute(
        (data) =>
            _resizeImageBytes(data['bytes'] as Uint8List, data['size'] as int),
        {'bytes': bytes, 'size': size},
      );

      // Save to app directory
      final String savedPath = await _saveImage(
        resizedBytes,
        subfolder,
        prefix,
      );
      return savedPath;
    } catch (e) {
      debugPrint('Error picking/resizing image: $e');
      return null;
    }
  }

  /// Pick image from camera and resize
  static Future<String?> pickFromCamera({
    required int size,
    required String subfolder,
    required String prefix,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final Uint8List bytes = await pickedFile.readAsBytes();
      final Uint8List resizedBytes = await compute(
        (data) =>
            _resizeImageBytes(data['bytes'] as Uint8List, data['size'] as int),
        {'bytes': bytes, 'size': size},
      );

      final String savedPath = await _saveImage(
        resizedBytes,
        subfolder,
        prefix,
      );
      return savedPath;
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Resize image bytes to target size (square crop)
  static Uint8List _resizeImageBytes(Uint8List bytes, int size) {
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) return bytes;

    // Calculate crop dimensions for square
    final int cropSize = original.width < original.height
        ? original.width
        : original.height;
    final int offsetX = (original.width - cropSize) ~/ 2;
    final int offsetY = (original.height - cropSize) ~/ 2;

    // Crop to square
    final img.Image cropped = img.copyCrop(
      original,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    // Resize to target size
    final img.Image resized = img.copyResize(
      cropped,
      width: size,
      height: size,
      interpolation: img.Interpolation.linear,
    );

    // Encode as JPEG with good quality
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  static Future<String> _saveImage(
    Uint8List bytes,
    String subfolder,
    String prefix,
  ) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = '${appDir.path}/images/$subfolder';

    // Create directory if not exists
    await Directory(imagesDir).create(recursive: true);

    // Generate filename with timestamp
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filename = '${prefix}_$timestamp.jpg';
    final String filePath = '$imagesDir/$filename';

    // Write file
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  /// Delete an image file
  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Check if image file exists
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    return File(imagePath).exists();
  }
}
