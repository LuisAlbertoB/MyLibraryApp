import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/models/library_item_model.dart';

/// Service for SQLite database operations.
class DatabaseService {
  static Database? _database;
  static const String _tableName = 'library_items';

  /// Get or initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'mini_reader.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            file_name TEXT NOT NULL,
            type TEXT NOT NULL,
            total_pages INTEGER DEFAULT 0,
            current_page INTEGER DEFAULT 0,
            thumbnail_path TEXT
          )
        ''');
      },
    );
  }

  /// Insert a new library item
  Future<void> insertItem(LibraryItemModel item) async {
    final db = await database;
    await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all library items
  Future<List<LibraryItemModel>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((map) => LibraryItemModel.fromMap(map)).toList();
  }

  /// Get item by file path
  Future<LibraryItemModel?> getItemByPath(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'file_path = ?',
      whereArgs: [path],
    );
    if (maps.isEmpty) return null;
    return LibraryItemModel.fromMap(maps.first);
  }

  /// Update reading progress
  Future<void> updateProgress(String id, int currentPage) async {
    final db = await database;
    await db.update(
      _tableName,
      {'current_page': currentPage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update item (totalPages, thumbnail, etc.)
  Future<void> updateItem(LibraryItemModel item) async {
    final db = await database;
    await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete item by id
  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete items not in the given paths (for cleanup)
  Future<void> deleteItemsNotIn(List<String> paths) async {
    final db = await database;
    if (paths.isEmpty) {
      await db.delete(_tableName);
      return;
    }
    final placeholders = paths.map((_) => '?').join(',');
    await db.delete(
      _tableName,
      where: 'file_path NOT IN ($placeholders)',
      whereArgs: paths,
    );
  }

  /// Remove duplicates (keep only one entry per file_path)
  /// This is needed to clean up legacy data with random IDs
  Future<void> removeDuplicates() async {
    final db = await database;
    // Delete rows where id is NOT the one we want to keep?
    // Hard to do complex logic in one query without deterministic knowledge.
    // Simpler: grouped by file path, keep LIMIT 1
    
    // Get all paths having count > 1
    final duplicates = await db.rawQuery('''
      SELECT file_path, COUNT(*) as c 
      FROM $_tableName 
      GROUP BY file_path 
      HAVING c > 1
    ''');
    
    for (final row in duplicates) {
      final path = row['file_path'] as String;
      // Get all items for this path
      final items = await db.query(
        _tableName,
        where: 'file_path = ?',
        whereArgs: [path],
      );
      
      // Heuristic: Keep the one where ID matches path.hashCode, or just the last one
      // Actually, if we have deterministic IDs now, we should keep the one that matches that ID format if possible,
      // or just keep any valid one.
      
      // Let's just keep the last inserted one (if we had timestamp) or just the first one.
      // Better: Delete ALL and let scanner re-add correct one? No, we lose progress.
      
      // Strategy: Keep the one with the highest current_page (progress)
      
      var bestItem = items.first;
      for (var item in items) {
        final bestPage = bestItem['current_page'] as int;
        final currPage = item['current_page'] as int;
        if (currPage > bestPage) {
          bestItem = item;
        }
      }
      
      // Delete others
      for (var item in items) {
        if (item['id'] != bestItem['id']) {
          await db.delete(_tableName, where: 'id = ?', whereArgs: [item['id']]);
        }
      }
    }
  }
}
