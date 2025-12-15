import 'dart:io';

/// Service for scanning directories for PDF and CBR/CBZ files.
class FileScannerService {
  /// Supported file extensions
  static const List<String> supportedExtensions = ['pdf', 'cbr', 'cbz'];

  /// Scan a directory recursively for supported files.
  /// 
  /// Returns a list of [File] objects matching PDF or CBR/CBZ extensions.
  Future<List<File>> scanDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    final List<File> foundFiles = [];

    if (!await directory.exists()) {
      return foundFiles;
    }

    await _scanRecursively(directory, foundFiles);
    
    // Sort by file name
    foundFiles.sort((a, b) => 
      a.path.split('/').last.toLowerCase().compareTo(
        b.path.split('/').last.toLowerCase()
      )
    );

    return foundFiles;
  }

  /// Recursively scan directory and subdirectories
  Future<void> _scanRecursively(Directory directory, List<File> results) async {
    try {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (supportedExtensions.contains(extension)) {
            results.add(entity);
          }
        } else if (entity is Directory) {
          // Skip hidden directories
          final dirName = entity.path.split('/').last;
          if (!dirName.startsWith('.')) {
            await _scanRecursively(entity, results);
          }
        }
      }
    } catch (e) {
      // Skip directories we can't access
      print('Error scanning directory: ${directory.path} - $e');
    }
  }

  /// Check if a file is a PDF
  bool isPdf(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Check if a file is a comic (CBR or CBZ)
  bool isComic(String filePath) {
    final lower = filePath.toLowerCase();
    return lower.endsWith('.cbr') || lower.endsWith('.cbz');
  }

  /// Check if a file is a CBZ (ZIP-based comic)
  bool isCbz(String filePath) {
    return filePath.toLowerCase().endsWith('.cbz');
  }

  /// Check if a file is a CBR (RAR-based comic)
  bool isCbr(String filePath) {
    return filePath.toLowerCase().endsWith('.cbr');
  }
}
