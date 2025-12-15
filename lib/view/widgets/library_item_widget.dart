import 'dart:io';
import 'package:flutter/material.dart';
import '../../model/entities/library_item.dart';

/// Widget for displaying a library item in the list.
class LibraryItemWidget extends StatelessWidget {
  final LibraryItem item;
  final VoidCallback onTap;

  const LibraryItemWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.isBook 
        ? const Color(0xFF2196F3)  // Blue for books
        : const Color(0xFFF44336); // Red for comics

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Color indicator / Thumbnail placeholder
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    image: item.thumbnailPath != null
                        ? DecorationImage(
                            image: FileImage(File(item.thumbnailPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.thumbnailPath == null
                      ? Center(
                          child: Icon(
                            item.isBook ? Icons.menu_book : Icons.auto_stories,
                            color: color,
                            size: 28,
                          ),
                        )
                      : null,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File name
                        Text(
                          item.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Type badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.isBook ? 'BOOK' : 'COMIC',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.totalPages} pages',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(item.progress * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
