import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for CBR/CBZ comic file operations.
/// 
/// CBZ files are ZIP archives, CBR files are RAR archives.
/// Both contain image files (usually JPG/PNG) representing comic pages.
class CbrService {
  /// Image extensions to look for in archives
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  /// Cache directory for extracted images
  Directory? _cacheDir;

  /// Get or create cache directory
  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'comic_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// Get the number of pages (images) in a comic archive
  Future<int> getPageCount(String filePath) async {
    try {
      if (_isCbz(filePath)) {
        return await _getCbzPageCount(filePath);
      } else if (_isCbr(filePath)) {
        return await _getCbrPageCount(filePath);
      }
      return 0;
    } catch (e) {
      print('Error getting comic page count: $e');
      return 0;
    }
  }

  /// Get page count for CBZ (ZIP-based)
  Future<int> _getCbzPageCount(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    int count = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final ext = entry.name.split('.').last.toLowerCase();
      if (imageExtensions.contains(ext)) {
        count++;
      }
    }
    return count;
  }

  /// Get page count for CBR (RAR-based)
  Future<int> _getCbrPageCount(String filePath) async {
    print('CBR (RAR) support is not available due to build limitations. Please convert to CBZ.');
    return 0;
  }

  /// Get a specific page image from the archive
  Future<Uint8List?> getPage(String filePath, int pageIndex) async {
    try {
      if (_isCbz(filePath)) {
        return await _getCbzPage(filePath, pageIndex);
      } else if (_isCbr(filePath)) {
        return await _getCbrPage(filePath, pageIndex);
      }
      return null;
    } catch (e) {
      print('Error getting comic page: $e');
      return null;
    }
  }

  /// Get page from CBZ file
  Future<Uint8List?> _getCbzPage(String filePath, int pageIndex) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    // Get sorted image files
    final imageFiles = archive.where((entry) {
      if (!entry.isFile) return false;
      final ext = entry.name.split('.').last.toLowerCase();
      return imageExtensions.contains(ext);
    }).toList();
    
    // Sort by name
    imageFiles.sort((a, b) => a.name.compareTo(b.name));
    
    if (pageIndex < 0 || pageIndex >= imageFiles.length) {
      return null;
    }

    final entry = imageFiles[pageIndex];
    return Uint8List.fromList(entry.content as List<int>);
  }

  /// Get page from CBR file (RAR-based)
  Future<Uint8List?> _getCbrPage(String filePath, int pageIndex) async {
    print('CBR (RAR) support is not available due to build limitations. Please convert to CBZ.');
    return null;
  }

  /// Generate thumbnail from first page
  Future<Uint8List?> generateThumbnail(String filePath) async {
    return await getPage(filePath, 0);
  }

  bool _isCbz(String filePath) => filePath.toLowerCase().endsWith('.cbz');
  bool _isCbr(String filePath) => filePath.toLowerCase().endsWith('.cbr');
  
  /// Helper to filter list by type
  Iterable<FileSystemEntity> whereType<T>() {
     // Not used directly, implementing Logic inside methods
     return [];
  }
}
