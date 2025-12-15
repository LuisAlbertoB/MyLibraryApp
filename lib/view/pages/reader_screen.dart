import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/entities/library_item.dart';
import '../../viewmodel/providers/reader_provider.dart';

/// Full-screen document reader with horizontal page navigation.
class ReaderScreen extends StatefulWidget {
  final LibraryItem item;

  const ReaderScreen({super.key, required this.item});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.item.currentPage);
    
    // Enter fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Open document
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReaderProvider>().openDocument(widget.item);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Exit fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ReaderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentPageImage == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.error != null && provider.currentPageImage == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Page viewer
                PageView.builder(
                  controller: _pageController,
                  itemCount: provider.totalPages,
                  onPageChanged: (page) {
                    provider.goToPage(page);
                  },
                  itemBuilder: (context, index) {
                    return _PageWidget(
                      pageIndex: index,
                      isCurrentPage: index == provider.currentPage,
                    );
                  },
                ),
                
                // Controls overlay
                if (_showControls) ...[
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () async {
                                  await provider.closeDocument();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                              Expanded(
                                child: Text(
                                  widget.item.fileName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom bar with progress
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: provider.totalPages > 0
                                      ? (provider.currentPage + 1) / provider.totalPages
                                      : 0,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.item.isBook
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFFF44336),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Page indicator
                              Text(
                                provider.progressText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                
                // Loading indicator
                if (provider.isLoading)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget for rendering a single page
class _PageWidget extends StatefulWidget {
  final int pageIndex;
  final bool isCurrentPage;

  const _PageWidget({
    required this.pageIndex,
    required this.isCurrentPage,
  });

  @override
  State<_PageWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<_PageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      final provider = context.read<ReaderProvider>();
      final data = await provider.getPageImage(widget.pageIndex);
      if (mounted) {
        setState(() {
          _imageData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (_error != null || _imageData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.white54, size: 48),
            const SizedBox(height: 8),
            Text(
              'Page ${widget.pageIndex + 1}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(
          _imageData!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
