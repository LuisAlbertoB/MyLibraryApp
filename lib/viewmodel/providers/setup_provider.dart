import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for initial setup flow (permissions + library directory selection).
class SetupProvider with ChangeNotifier {
  static const String _libraryPathKey = 'library_path';
  static const String _setupCompleteKey = 'setup_complete';

  bool _hasPermission = false;
  String? _libraryPath;
  bool _isLoading = false;
  String? _error;
  bool _setupComplete = false;

  // Getters
  bool get hasPermission => _hasPermission;
  String? get libraryPath => _libraryPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get setupComplete => _setupComplete;
  bool get canComplete => _hasPermission && _libraryPath != null;

  /// Initialize provider, load saved preferences
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _libraryPath = prefs.getString(_libraryPathKey);
      _setupComplete = prefs.getBool(_setupCompleteKey) ?? false;
      
      // Check current permission status
      _hasPermission = await _checkStoragePermission();
    } catch (e) {
      _error = 'Error initializing: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if storage permission is granted
  Future<bool> _checkStoragePermission() async {
    // For Android 11+ we need MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    // Fallback to regular storage permission
    if (await Permission.storage.isGranted) {
      return true;
    }
    return false;
  }

  /// Request storage permission
  Future<void> requestStoragePermission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try MANAGE_EXTERNAL_STORAGE first (Android 11+)
      PermissionStatus status = await Permission.manageExternalStorage.request();
      
      if (status.isGranted) {
        _hasPermission = true;
      } else {
        // Fallback to regular storage
        status = await Permission.storage.request();
        _hasPermission = status.isGranted;
      }

      if (!_hasPermission) {
        if (status.isPermanentlyDenied) {
          _error = 'Permission denied. Please enable in Settings.';
        } else {
          _error = 'Storage permission required.';
        }
      }
    } catch (e) {
      _error = 'Error requesting permission: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open settings for manually granting permission
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Select library directory
  Future<void> selectLibraryDirectory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Library Folder',
      );

      if (result != null) {
        _libraryPath = result;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_libraryPathKey, result);
      } else {
        _error = 'No directory selected.';
      }
    } catch (e) {
      _error = 'Error selecting directory: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Complete setup and save state
  Future<void> completeSetup() async {
    if (!canComplete) {
      _error = 'Please grant permissions and select a directory.';
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_setupCompleteKey, true);
      _setupComplete = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error saving setup: $e';
      notifyListeners();
    }
  }

  /// Reset setup (for testing)
  Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_libraryPathKey);
    await prefs.remove(_setupCompleteKey);
    _libraryPath = null;
    _setupComplete = false;
    notifyListeners();
  }
}
