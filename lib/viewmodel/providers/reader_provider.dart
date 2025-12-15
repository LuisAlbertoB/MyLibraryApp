import 'package:flutter/foundation.dart';
import '../../model/entities/library_item.dart';
import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../services/cbr_service.dart';

/// Provider for document reader state.
class ReaderProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final PdfService _pdfService = PdfService();
  final CbrService _cbrService = CbrService();

  LibraryItem? _currentItem;
  int _currentPage = 0;
  Uint8List? _currentPageImage;
  bool _isLoading = false;
  String? _error;

  // Getters
  LibraryItem? get currentItem => _currentItem;
  int get currentPage => _currentPage;
  Uint8List? get currentPageImage => _currentPageImage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get totalPages => _currentItem?.totalPages ?? 0;
  bool get canGoNext => _currentPage < totalPages - 1;
  bool get canGoPrevious => _currentPage > 0;
  
  /// Progress text for display
  String get progressText => '${_currentPage + 1} / $totalPages';

  /// Open a document for reading
  Future<void> openDocument(LibraryItem item) async {
    _isLoading = true;
    _error = null;
    _currentItem = item;
    _currentPage = item.currentPage; // Resume from saved position
    notifyListeners();

    try {
      await _loadCurrentPage();
    } catch (e) {
      _error = 'Error opening document: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the current page image
  Future<void> _loadCurrentPage() async {
    if (_currentItem == null) return;

    try {
      if (_currentItem!.isBook) {
        _currentPageImage = await _pdfService.renderPage(
          _currentItem!.filePath, 
          _currentPage,
        );
      } else {
        _currentPageImage = await _cbrService.getPage(
          _currentItem!.filePath, 
          _currentPage,
        );
      }
    } catch (e) {
      _error = 'Error loading page: $e';
      _currentPageImage = null;
    }
  }

  /// Go to a specific page
  Future<void> goToPage(int page) async {
    if (_currentItem == null) return;
    if (page < 0 || page >= totalPages) return;
    if (page == _currentPage) return;

    _isLoading = true;
    notifyListeners();

    _currentPage = page;
    
    try {
      await _loadCurrentPage();
      await _saveProgress();
    } catch (e) {
      _error = 'Error navigating: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to next page
  Future<void> nextPage() async {
    if (canGoNext) {
      await goToPage(_currentPage + 1);
    }
  }

  /// Go to previous page
  Future<void> previousPage() async {
    if (canGoPrevious) {
      await goToPage(_currentPage - 1);
    }
  }

  /// Save current progress to database
  Future<void> _saveProgress() async {
    if (_currentItem == null) return;
    
    try {
      await _databaseService.updateProgress(_currentItem!.id, _currentPage);
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  /// Close document and save progress
  Future<void> closeDocument() async {
    await _saveProgress();
    _currentItem = null;
    _currentPage = 0;
    _currentPageImage = null;
    _error = null;
    notifyListeners();
  }

  /// Get page image for PageView (pre-rendering)
  Future<Uint8List?> getPageImage(int pageIndex) async {
    if (_currentItem == null) return null;
    if (pageIndex < 0 || pageIndex >= totalPages) return null;

    try {
      if (_currentItem!.isBook) {
        return await _pdfService.renderPage(_currentItem!.filePath, pageIndex);
      } else {
        return await _cbrService.getPage(_currentItem!.filePath, pageIndex);
      }
    } catch (e) {
      print('Error getting page $pageIndex: $e');
      return null;
    }
  }
}
