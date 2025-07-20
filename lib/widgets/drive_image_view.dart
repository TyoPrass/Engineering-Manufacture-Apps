import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DriveImageView extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const DriveImageView({
    Key? key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's a local file path or a URL
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Center(
          child: Container(
            width: 40,
            height: 40,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('Error loading image from $url: $error');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                const SizedBox(height: 4),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        },
        fadeInDuration: const Duration(milliseconds: 300),
      );
    } else if (url.isNotEmpty) {
      // For local files
      try {
        final file = File(url);
        if (!file.existsSync()) {
          return _buildPlaceholder('File not found');
        }

        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading local image from $url: $error');
            return _buildPlaceholder('Error loading image');
          },
        );
      } catch (e) {
        print('Exception while loading local image: $e');
        return _buildPlaceholder('Error loading image');
      }
    } else {
      // Fallback for empty URL
      return _buildPlaceholder('No image');
    }
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 40, color: Colors.grey),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
