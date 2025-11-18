import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../constants/image_paths.dart';

/// A service to handle image loading with caching and error handling
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Cache to store pre-loaded images
  final Map<String, ui.Image?> _imageCache = {};

  /// Preloads a set of images and caches them for quick access
  Future<void> preloadImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      try {
        final image = await _loadImageFromAsset(path);
        _imageCache[path] = image;
      } catch (e) {
        debugPrint('Error preloading image $path: $e');
        _imageCache[path] = null;
      }
    }
  }

  /// Loads an image from assets with error handling
  Future<ui.Image?> _loadImageFromAsset(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } catch (e) {
      debugPrint('Error loading image from asset: $path - $e');
      return null;
    }
  }

  /// Gets an ImageProvider with fallback for asset images
  ImageProvider getImageProvider(String path, {String? fallbackPath}) {
    return AssetImage(path);
  }

  /// Get a safe image provider that will fall back to defaults if the image fails to load
  ImageProvider getSafeImageProvider(String imagePath) {
    try {
      return AssetImage(imagePath);
    } catch (e) {
      debugPrint('Image error: $e');
      return AssetImage(DefaultImages.facultyFallback);
    }
  }

  /// Check if an image path exists and is valid in the app's assets
  Future<bool> imageExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Preloads faculty images for better performance
  Future<void> preloadFacultyImages() async {
    final facultyPaths = [
      FacultyImages.noori,
      FacultyImages.fokhray,
      FacultyImages.aminul,
      FacultyImages.allayear,
      FacultyImages.sadi,
      FacultyImages.imran,
      FacultyImages.sarowar,
      DefaultImages.facultyFallback,
    ];

    await preloadImages(facultyPaths);
    debugPrint('Faculty images preloaded');
  }

  /// Clear the image cache to free up memory
  void clearCache() {
    _imageCache.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
