import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/utils/cached_image.dart';

class PhotoGalleryPage extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryPage({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  late final PageController _controller;
  late int _currentIndex;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _dragOffset += details.delta.dy;
                  if (_dragOffset < 0) _dragOffset = 0;
                });
              },
              onVerticalDragEnd: (_) {
                if (_dragOffset > 120) {
                  _close();
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              onVerticalDragCancel: () => setState(() => _dragOffset = 0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: Opacity(
                      opacity: (1 - _dragOffset / (screen.height * 0.8))
                          .clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Center(
                      child: CachedImage.widget(
                        photos[index],
                        width: screen.width,
                        height: screen.height,
                        fit: BoxFit.contain,
                        errorWidget: Container(
                          color: Colors.black,
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Stack(
                  children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(photos.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentIndex == index
                                    ? AppTheme.textOnPhoto
                                    : AppTheme.textOnPhoto.withValues(
                                        alpha: 0.4,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
