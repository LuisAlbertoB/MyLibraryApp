/// Library item types
enum ItemType { 
  /// PDF files (books)
  book, 
  /// CBR/CBZ files (comics)
  comic 
}

/// Entity representing a library item (book or comic).
/// 
/// This is a pure domain entity with no serialization logic.
class LibraryItem {
  final String id;
  final String filePath;
  final String fileName;
  final ItemType type;
  final int totalPages;
  final int currentPage;
  final String? thumbnailPath;

  LibraryItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.totalPages = 0,
    this.currentPage = 0,
    this.thumbnailPath,
  });

  /// Reading progress as percentage (0.0 - 1.0)
  double get progress => totalPages > 0 ? currentPage / totalPages : 0;

  /// Whether this item is a book (PDF)
  bool get isBook => type == ItemType.book;

  /// Whether this item is a comic (CBR/CBZ)
  bool get isComic => type == ItemType.comic;

  /// File extension from path
  String get extension => filePath.split('.').last.toLowerCase();
}
