import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class ImageGalleryGrid extends StatelessWidget {
  final List<String> imageUris;

  const ImageGalleryGrid({super.key, required this.imageUris});

  @override
  Widget build(BuildContext context) {
    if (imageUris.isEmpty) return const SizedBox.shrink();

    final count = imageUris.length;

    Widget content;
    if (count == 1) {
      content = _buildSingleImage(context, imageUris[0], 0);
    } else if (count == 2) {
      content = _buildTwoImages(context);
    } else if (count == 3) {
      content = _buildThreeImages(context);
    } else {
      content = _buildFourPlusImages(context);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _buildImageTile(BuildContext context, String uri, int index, {BoxFit fit = BoxFit.cover}) {
    final isLocal = !uri.startsWith('http');
    final imageWidget = isLocal
        ? Image.file(
            File(uri),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _errorPlaceholder(),
          )
        : Image.network(
            uri,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _errorPlaceholder(),
          );

    return GestureDetector(
      onTap: () => _openLightbox(context, index),
      child: Hero(
        tag: 'gallery_${uri}_$index',
        child: imageWidget,
      ),
    );
  }

  Widget _errorPlaceholder() {
    return Container(
      color: SlipTheme.surface,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 24, color: SlipTheme.steel),
      ),
    );
  }

  Widget _buildSingleImage(BuildContext context, String uri, int index) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      width: double.infinity,
      color: SlipTheme.surface,
      child: _buildImageTile(context, uri, index, fit: BoxFit.contain),
    );
  }

  Widget _buildTwoImages(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          Expanded(child: _buildImageTile(context, imageUris[0], 0)),
          const SizedBox(width: 4),
          Expanded(child: _buildImageTile(context, imageUris[1], 1)),
        ],
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildImageTile(context, imageUris[0], 0),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildImageTile(context, imageUris[1], 1)),
                const SizedBox(height: 3),
                Expanded(child: _buildImageTile(context, imageUris[2], 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourPlusImages(BuildContext context) {
    final extraCount = imageUris.length - 4;
    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUris[0], 0)),
                const SizedBox(width: 3),
                Expanded(child: _buildImageTile(context, imageUris[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUris[2], 2)),
                const SizedBox(width: 3),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageTile(context, imageUris[3], 3),
                      if (extraCount > 0)
                        GestureDetector(
                          onTap: () => _openLightbox(context, 3),
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+$extraCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _LightboxDialog(
          imageUris: imageUris,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _LightboxDialog extends StatefulWidget {
  final List<String> imageUris;
  final int initialIndex;

  const _LightboxDialog({
    required this.imageUris,
    required this.initialIndex,
  });

  @override
  State<_LightboxDialog> createState() => _LightboxDialogState();
}

class _LightboxDialogState extends State<_LightboxDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Stack(
          children: [
            // Page view for images
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUris.length,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemBuilder: (context, index) {
                final uri = widget.imageUris[index];
                final isLocal = !uri.startsWith('http');
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 6.0,
                  child: Center(
                    child: isLocal
                        ? Image.file(
                            File(uri),
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            uri,
                            fit: BoxFit.contain,
                          ),
                  ),
                );
              },
            ),

            // Top Bar with Close button and image counter
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1} of ${widget.imageUris.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
