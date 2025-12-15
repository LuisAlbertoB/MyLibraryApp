import '../entities/library_item.dart';

/// Data model for LibraryItem with database serialization.
class LibraryItemModel extends LibraryItem {
  LibraryItemModel({
    required super.id,
    required super.filePath,
    required super.fileName,
    required super.type,
    super.totalPages,
    super.currentPage,
    super.thumbnailPath,
  });

  /// Create from database map
  factory LibraryItemModel.fromMap(Map<String, dynamic> map) {
    return LibraryItemModel(
      id: map['id'] as String,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      type: map['type'] == 'book' ? ItemType.book : ItemType.comic,
      totalPages: map['total_pages'] as int? ?? 0,
      currentPage: map['current_page'] as int? ?? 0,
      thumbnailPath: map['thumbnail_path'] as String?,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'type': type == ItemType.book ? 'book' : 'comic',
      'total_pages': totalPages,
      'current_page': currentPage,
      'thumbnail_path': thumbnailPath,
    };
  }

  /// Create a copy with updated fields
  LibraryItemModel copyWith({
    String? id,
    String? filePath,
    String? fileName,
    ItemType? type,
    int? totalPages,
    int? currentPage,
    String? thumbnailPath,
  }) {
    return LibraryItemModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
