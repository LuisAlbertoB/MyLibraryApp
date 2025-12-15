import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/providers/library_provider.dart';
import '../../model/entities/folder_node.dart';
import '../../model/entities/library_item.dart';
import 'library_item_widget.dart';

/// Recursive widget to display a folder and its contents
class FolderWidget extends StatefulWidget {
  final FolderNode node;
  final Function(LibraryItem) onItemTap;
  final int level;

  const FolderWidget({
    super.key,
    required this.node,
    required this.onItemTap,
    this.level = 0,
  });

  @override
  State<FolderWidget> createState() => _FolderWidgetState();
}

class _FolderWidgetState extends State<FolderWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.node.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder Header (only if not root or root has been explicitly named)
        // Usually we want to show root too, or maybe just subfolders
        // If level 0 is "Library", we might want to show it as an open header
        
        if (widget.level >= 0)
          Padding(
            padding: EdgeInsets.only(left: widget.level * 8.0, bottom: 4),
            child: _buildSwipeableHeader(context),
          ),

        // Content
        if (_isExpanded)
          Padding(
             padding: EdgeInsets.only(left: (widget.level + 1) * 12.0),
             child: Column(
               children: [
                 // Subfolders
                 ...widget.node.subfolders.map((subfolder) => FolderWidget(
                   node: subfolder,
                   onItemTap: widget.onItemTap,
                   level: widget.level + 1,
                 )),
                 
                 // Files
                 if (widget.node.files.isNotEmpty)
                    ...widget.node.files.map((file) => LibraryItemWidget(
                      item: file,
                      onTap: () => widget.onItemTap(file),
                    )),
               ],
             ),
          ),
      ],
    );
  }

  double _dragOffset = 0.0;
  static const double _maxDrag = 200.0; // Width of color panel

  Widget _buildSwipeableHeader(BuildContext context) {
    return Stack(
      children: [
        // Color Palette Panel (Background)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Only scroll by drag? No, just static
              child: Row(
                children: [
                   _buildColorCircle(Colors.amber),
                   _buildColorCircle(Colors.orange),
                   _buildColorCircle(Colors.redAccent),
                   _buildColorCircle(Colors.pinkAccent),
                   _buildColorCircle(Colors.purpleAccent),
                   _buildColorCircle(Colors.indigoAccent),
                   _buildColorCircle(Colors.blueAccent),
                   _buildColorCircle(Colors.cyan),
                   _buildColorCircle(Colors.teal),
                   _buildColorCircle(Colors.green),
                ],
              ),
            ),
          ),
        ),

        // Foreground Header
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx;
              // Limit drag logic
              if (_dragOffset < 0) _dragOffset = 0;
              if (_dragOffset > _maxDrag) _dragOffset = _maxDrag;
            });
          },
          onHorizontalDragEnd: (details) {
             // Snap logic
             if (_dragOffset > _maxDrag / 2) {
               setState(() => _dragOffset = _maxDrag);
             } else {
               setState(() => _dragOffset = 0.0);
             }
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Material(
              color: const Color(0xFF667eea), // Opaque background to hide panel (match simplified gradient part or solid)
              // Actually we need a solid color for the header background so it hides the panel
              // But our main background is gradient.
              // Let's use a dark semi-transparent background that looks good?
              // Or just Colors.grey[900]
              
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                   if (_dragOffset > 0) {
                     setState(() => _dragOffset = 0.0); // Close panel
                   } else {
                     setState(() {
                       _isExpanded = !_isExpanded;
                       widget.node.isExpanded = _isExpanded;
                     });
                   }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87, // Solid color for swipeable item
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                         _dragOffset > 0 ? Icons.palette : (_isExpanded ? Icons.folder_open : Icons.folder),
                        color: widget.node.folderColor, 
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.node.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_more : Icons.chevron_right,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        // Update color
        final provider = context.read<LibraryProvider>();
        provider.updateFolderColor(widget.node.name, color); // Ideally use path, but name is used in logic
        
        setState(() {
          widget.node.folderColor = color;
          _dragOffset = 0.0; // Close panel
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}
