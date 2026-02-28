/// Image service for picking and resizing images
/// Automatically resizes mobile photos to save storage
library;

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Cross-platform logo picker: works on Web, Android, Windows
  /// Uses file_picker (works everywhere) + Firebase Storage for URL
  /// Returns the download URL string on success, null on cancel/error
  static Future<String?> pickAndUploadLogo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Use file_picker which works on all platforms
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // needed for web
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) return null;

      // Resize image (use compute on non-web, direct call on web)
      Uint8List resizedBytes;
      if (kIsWeb) {
        resizedBytes = _resizeImageBytes(bytes, ImageSizes.logoSize);
      } else {
        resizedBytes = await compute(
          (data) => _resizeImageBytes(
            data['bytes'] as Uint8List,
            data['size'] as int,
          ),
          {'bytes': bytes, 'size': ImageSizes.logoSize},
        );
      }

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$uid/shop_logo.jpg',
      );

      await storageRef.putData(
        resizedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking/uploading logo: $e');
      return null;
    }
  }

  /// Cross-platform product image picker: works on Web, Android, Windows
  /// Uploads to Firebase Storage under users/$uid/products/
  /// Returns the download URL string on success, null on cancel/error
  static Future<String?> pickAndUploadProductImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) return null;

      // Resize to product thumbnail size
      Uint8List resizedBytes;
      if (kIsWeb) {
        resizedBytes = _resizeImageBytes(
          bytes,
          ImageSizes.productThumbnailSize,
        );
      } else {
        resizedBytes = await compute(
          (data) => _resizeImageBytes(
            data['bytes'] as Uint8List,
            data['size'] as int,
          ),
          {'bytes': bytes, 'size': ImageSizes.productThumbnailSize},
        );
      }

      // Upload to Firebase Storage with unique name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$uid/products/product_$timestamp.jpg',
      );

      await storageRef.putData(
        resizedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking/uploading product image: $e');
      return null;
    }
  }

  /// Cross-platform profile image picker: works on Web, Android, Windows
  /// Uploads to Firebase Storage as profile_image.jpg (separate from shop logo)
  /// Returns the download URL string on success, null on cancel/error
  static Future<String?> pickAndUploadProfileImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Use file_picker which works on all platforms
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // needed for web
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) return null;

      // Resize image (use compute on non-web, direct call on web)
      Uint8List resizedBytes;
      if (kIsWeb) {
        resizedBytes = _resizeImageBytes(bytes, ImageSizes.logoSize);
      } else {
        resizedBytes = await compute(
          (data) => _resizeImageBytes(
            data['bytes'] as Uint8List,
            data['size'] as int,
          ),
          {'bytes': bytes, 'size': ImageSizes.logoSize},
        );
      }

      // Upload to Firebase Storage (different path from shop logo)
      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$uid/profile_image.jpg',
      );

      await storageRef.putData(
        resizedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error picking/uploading profile image: $e');
      return null;
    }
  }

  /// Delete logo from Firebase Storage
  static Future<void> deleteLogoFromStorage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseStorage.instance
          .ref()
          .child('users/$uid/shop_logo.jpg')
          .delete();
    } catch (e) {
      debugPrint('Error deleting logo from storage: $e');
    }
  }

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
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Check if image file exists
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    return File(imagePath).existsSync();
  }
}
