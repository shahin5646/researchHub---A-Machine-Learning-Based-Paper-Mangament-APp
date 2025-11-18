import 'package:flutter/material.dart';
import '../constants/image_paths.dart';
import '../services/image_service.dart';

class SafeImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? fallbackPath;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackPath,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Try fallback image first
        if (fallbackPath != null) {
          return Image.asset(
            fallbackPath!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultErrorWidget();
            },
          );
        }

        // Try default faculty fallback
        return Image.asset(
          DefaultImages.facultyFallback,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultErrorWidget();
          },
        );
      },
      // Image.asset doesn't support loadingBuilder
      // We'll use placeholder widget directly
    );
  }

  Widget _buildDefaultErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person,
            size: (width != null && height != null)
                ? (width! < height! ? width! * 0.6 : height! * 0.6)
                : 24,
            color: Colors.grey[600],
          ),
        );
  }
}

class SafeCircleAvatar extends StatelessWidget {
  final String imagePath;
  final double radius;
  final String? fallbackPath;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
    this.fallbackPath,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.transparent,
      child: ClipOval(
        child: SafeImage(
          imagePath: imagePath,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          fallbackPath: fallbackPath,
          errorWidget: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
