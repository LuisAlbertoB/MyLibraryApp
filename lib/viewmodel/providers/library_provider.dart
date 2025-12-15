import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../model/entities/library_item.dart';
import '../../../model/entities/folder_node.dart';
import '../../../model/models/library_item_model.dart';
import '../../../services/database_service.dart';
import '../../../services/file_scanner_service.dart';
import '../../../services/pdf_service.dart';
import '../../../services/cbr_service.dart';

/// Filter options for library view
enum LibraryFilter { all, books, comics }

/// Provider for library management and state.
class LibraryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FileScannerService _fileScannerService = FileScannerService();
  final PdfService _pdfService = PdfService();
  final CbrService _cbrService = CbrService();

  List<LibraryItemModel> _items = [];
  FolderNode? _rootNode; // Logic root for tree view
  
  LibraryFilter _filter = LibraryFilter.all;
  bool _isScanning = false;
  String? _error;
  String? _libraryPath;

  // Getters
  List<LibraryItem> get items => _items;
  FolderNode? get rootNode => _rootNode;
  LibraryFilter get filter => _filter;
  bool get isScanning => _isScanning;
  String? get error => _error;
  String? get libraryPath => _libraryPath;

  /// Get filtered items based on current filter
  List<LibraryItem> get filteredItems {
    switch (_filter) {
      case LibraryFilter.books:
        return _items.where((item) => item.isBook).toList();
      case LibraryFilter.comics:
        return _items.where((item) => item.isComic).toList();
      case LibraryFilter.all:
        return _items;
    }
  }

  /// Counts for UI
  int get totalCount => _items.length;
  int get booksCount => _items.where((item) => item.isBook).length;
  int get comicsCount => _items.where((item) => item.isComic).length;

  /// Set library path
  void setLibraryPath(String path) {
    _libraryPath = path;
  }

  /// Set filter
  void setFilter(LibraryFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  /// Load items from database
  Future<void> loadItems() async {
    try {
      _items = await _databaseService.getAllItems();
      _buildTree(); // Rebuild tree from flat list
      notifyListeners();
    } catch (e) {
      _error = 'Error loading items: $e';
      notifyListeners();
    }
  }

  /// Scan library directory and update database
  Future<void> scanLibrary() async {
    if (_libraryPath == null) {
      _error = 'Library path not set';
      notifyListeners();
      return;
    }

    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      // Scan directory for files
      final files = await _fileScannerService.scanDirectory(_libraryPath!);
      final filePaths = files.map((f) => f.path).toList();

      // Remove items no longer in directory
      await _databaseService.deleteItemsNotIn(filePaths);

      // Process each file
      for (final file in files) {
        await _processFile(file);
      }

      // Reload from database
      await loadItems();
      
      // Start background thumbnail generation
      _generateMissingThumbnails();
    } catch (e) {
      _error = 'Error scanning library: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Process a single file
  Future<void> _processFile(File file) async {
    try {
      // Check if already in database
      final existing = await _databaseService.getItemByPath(file.path);
      if (existing != null) {
        // Already processed
        return;
      }

      final fileName = file.path.split('/').last;
      final isPdf = _fileScannerService.isPdf(file.path);
      final itemType = isPdf ? ItemType.book : ItemType.comic;

      // Get page count
      int totalPages = 0;
      if (isPdf) {
        totalPages = await _pdfService.getPageCount(file.path);
      } else {
        totalPages = await _cbrService.getPageCount(file.path);
      }

      // Create item
      // Use deterministic ID based on file path to avoid duplicates
      final id = file.path.hashCode.toString();
      final item = LibraryItemModel(
        id: id,
        filePath: file.path,
        fileName: fileName,
        type: itemType,
        totalPages: totalPages,
        currentPage: 0,
        thumbnailPath: null,
      );

      // Save to database
      await _databaseService.insertItem(item);
    } catch (e) {
      print('Error processing file ${file.path}: $e');
    }
  }

  /// Build directory tree from flat item list
  void _buildTree() {
    if (_items.isEmpty || _libraryPath == null) {
      _rootNode = null;
      return;
    }

    // Filter items first if needed, but usually tree shows all and folders hide/show
    // For now, let's build tree with ALL items, UI can filter
    
    // Group items by directory
    // We assume _libraryPath is the root
    
    final root = FolderNode(
      name: 'Library', 
      path: _libraryPath!,
      isExpanded: true,
      folderColor: Colors.purple.shade200, // Root color
      subfolders: [],
      files: [],
    );

    // Recursively add items
    for (final item in _items) {
       _addItemToTree(root, item);
    }
    
    _rootNode = root;
  }

  /// Recursive helper to add item to tree
  void _addItemToTree(FolderNode root, LibraryItemModel item) {
    if (!item.filePath.startsWith(root.path)) return;

    // Relative path from root
    String relativePath = item.filePath.substring(root.path.length);
    if (relativePath.startsWith(Platform.pathSeparator)) relativePath = relativePath.substring(1);
    
    final parts = relativePath.split(Platform.pathSeparator);
    // last part is filename
    
    if (parts.length == 1) {
      // It's a file in this folder
      root.files.add(item);
    } else {
      // It's in a subfolder
      FolderNode current = root;
      
      // Navigate/Create folder structure
      for (int i = 0; i < parts.length - 1; i++) {
         final part = parts[i];
         
         // Find subfolder
         var next = current.subfolders.firstWhere(
           (s) => s.name == part,
           orElse: () {
             // Create if not exists
             final newP = '${current.path}${Platform.pathSeparator}$part';
             final newFolder = FolderNode(
               name: part, 
               path: newP,
               folderColor: _getFolderColor(part),
               subfolders: [], // Mutable list
               files: [],      // Mutable list
             );
             current.subfolders.add(newFolder);
             return newFolder;
           }
         );
         current = next;
      }
      // Add file to the leaf folder
      current.files.add(item);
    }
  }

  Color _getFolderColor(String name) {
    final colors = [
      Colors.amber,
      Colors.orange,
      Colors.teal,
      Colors.cyan,
      Colors.indigoAccent,
      Colors.pinkAccent,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  /// Generate thumbnails for items that don't have one
  Future<void> _generateMissingThumbnails() async {
    final itemsWithoutThumbnail = _items.where((i) => i.thumbnailPath == null).toList();
    
    for (final item in itemsWithoutThumbnail) {
      // Check if we are still scanning or if app is disposed (omitted for brevity)
      
      try {
        // Significant delay to allow UI to render and GC to run
        await Future.delayed(const Duration(milliseconds: 500));
        
        final thumbnailPath = await _generateThumbnail(item);
        if (thumbnailPath != null) {
          final updatedItem = item.copyWith(thumbnailPath: thumbnailPath);
          await _databaseService.updateItem(updatedItem);
          
          // Update local list in place to avoid full reload
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = updatedItem;
            notifyListeners(); // Notify for each thumbnail update
          }
        }
      } catch (e) {
        print('Error generating thumbnail for ${item.fileName}: $e');
      }
    }
  }

  /// Generate and save thumbnail for an item
  Future<String?> _generateThumbnail(LibraryItemModel item) async {
    try {
      Uint8List? thumbBytes;
      if (item.isBook) {
        thumbBytes = await _pdfService.generateThumbnail(item.filePath);
      } else {
        thumbBytes = await _cbrService.generateThumbnail(item.filePath);
      }

      if (thumbBytes == null || thumbBytes.isEmpty) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${appDir.path}/thumbnails');
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final thumbFile = File('${thumbDir.path}/${item.id}.png');
      await thumbFile.writeAsBytes(thumbBytes);
      
      return thumbFile.path;
    } catch (e) {
      print('Error generating thumbnail for ${item.fileName}: $e');
      return null;
    }
  }

  /// Update reading progress for an item
  Future<void> updateProgress(String itemId, int currentPage) async {
    try {
      await _databaseService.updateProgress(itemId, currentPage);
      
      // Update local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(currentPage: currentPage);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating progress: $e';
      notifyListeners();
    }
  }

  /// Get item by ID
  LibraryItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh library (rescan)
  Future<void> refresh() async {
    await scanLibrary();
  }
}
