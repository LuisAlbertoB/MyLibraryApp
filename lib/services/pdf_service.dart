import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdfrx/pdfrx.dart';

/// Service for PDF file operations using pdfrx.
class PdfService {
  /// Get the number of pages in a PDF file
  Future<int> getPageCount(String filePath) async {
    try {
      final document = await PdfDocument.openFile(filePath);
      final pageCount = document.pages.length;
      document.dispose();
      return pageCount;
    } catch (e) {
      print('Error getting PDF page count: $e');
      return 0;
    }
  }

  /// Render a specific page as an image
  Future<Uint8List?> renderPage(String filePath, int pageIndex, {double scale = 2.0}) async {
    try {
      final document = await PdfDocument.openFile(filePath);
      
      if (pageIndex < 0 || pageIndex >= document.pages.length) {
        document.dispose();
        return null;
      }

      final page = document.pages[pageIndex];
      final pageImage = await page.render(
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
      );
      
      if (pageImage == null) {
        document.dispose();
        return null;
      }

      // Convert to PNG bytes
      final image = await _convertToImage(pageImage);
      document.dispose();
      
      return image;
    } catch (e) {
      print('Error rendering PDF page: $e');
      return null;
    }
  }

  /// Generate a thumbnail from the first page
  Future<Uint8List?> generateThumbnail(String filePath) async {
    return await renderPage(filePath, 0, scale: 0.5);
  }

  /// Convert PdfImage to PNG bytes
  Future<Uint8List?> _convertToImage(PdfImage pageImage) async {
    try {
      final pixels = pageImage.pixels;
      final width = pageImage.width;
      final height = pageImage.height;

      // Create ui.Image from raw pixels
      final completer = ui.ImmutableBuffer.fromUint8List(pixels);
      final buffer = await completer;
      
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Convert to PNG
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting PDF page to image: $e');
      return null;
    }
  }
}
