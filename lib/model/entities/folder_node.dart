import 'package:flutter/material.dart';
import 'library_item.dart';

/// Represents a folder in the library tree structure.
class FolderNode {
  final String name;
  final String path;
  final List<FolderNode> subfolders;
  final List<LibraryItem> files;
  bool isExpanded;
  Color folderColor;

  FolderNode({
    required this.name,
    required this.path,
    this.subfolders = const [],
    this.files = const [],
    this.isExpanded = false,
    this.folderColor = Colors.amber, // Default color
  });

  /// Check if the folder is empty (no files recursively)
  bool get isEmpty => files.isEmpty && subfolders.every((s) => s.isEmpty);
  
  /// Total items count recursively
  int get totalItems => files.length + subfolders.fold(0, (sum, node) => sum + node.totalItems);
}
