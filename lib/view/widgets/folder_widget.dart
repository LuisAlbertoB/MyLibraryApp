import 'package:flutter/material.dart';
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
        
        if (widget.level >= 0) // Always show header for now
          Padding(
            padding: EdgeInsets.only(left: widget.level * 8.0, bottom: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    widget.node.isExpanded = _isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isExpanded ? Colors.white.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Folder Icon
                      Icon(
                        _isExpanded ? Icons.folder_open : Icons.folder,
                        color: widget.node.folderColor, // Use custom folder color
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      
                      // Folder Name
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
                      
                      // Collapse/Expand Icon
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
}
