import 'dart:ui';
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

  Future<bool> _showExitConfirmation() async {
    // Show dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // We handle blur manually if needed, or use proper blur barrier
      builder: (context) {
        return Stack(
           children: [
             // Blur Effect
             Positioned.fill(
               child: BackdropFilter(
                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                 child: Container(
                   color: Colors.black.withOpacity(0.3),
                 ),
               ),
             ),
             // Dialog
             Center(
               child: Container(
                 margin: const EdgeInsets.symmetric(horizontal: 32),
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: const Color(0xFF2d3436),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.white24),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.5),
                       blurRadius: 16,
                       spreadRadius: 4,
                     ),
                   ],
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.menu_book, color: Colors.white, size: 48),
                     const SizedBox(height: 16),
                     const Text(
                       '¿Deseas salir?',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 20, 
                         fontWeight: FontWeight.bold,
                         decoration: TextDecoration.none
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 12),
                     const Text(
                       'Deseo continuar leyendo o prefiero salir, mi progreso se guardara',
                       style: TextStyle(
                         color: Colors.white70,
                         fontSize: 14,
                         decoration: TextDecoration.none,
                         fontWeight: FontWeight.normal
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                       children: [
                         // Continue Button
                         TextButton(
                           onPressed: () => Navigator.of(context).pop(false),
                           style: TextButton.styleFrom(
                             foregroundColor: Colors.white70,
                           ),
                           child: const Text('Continuar'),
                         ),
                         // Exit Button
                         ElevatedButton.icon(
                           onPressed: () => Navigator.of(context).pop(true),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.redAccent,
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8),
                             ),
                           ),
                           icon: const Icon(Icons.exit_to_app, size: 18),
                           label: const Text('Salir'),
                         ),
                       ],
                     )
                   ],
                 ),
               ),
             ),
           ],
        );
      },
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await _showExitConfirmation();
        if (shouldExit && context.mounted) {
          // Close document and navigate back
           final provider = context.read<ReaderProvider>();
           await provider.closeDocument();
           if (context.mounted) {
             Navigator.of(context).pop();
           }
        }
      },
      child: Scaffold(
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
                                  // Trigger system back handling which calls onPopInvoked
                                  if (context.mounted) {
                                     Navigator.of(context).maybePop();
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
