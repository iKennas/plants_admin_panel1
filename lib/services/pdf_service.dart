import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/customer.dart';
import '../models/sheet.dart';
import '../utils/constants.dart';

/// Local PDF generation service
/// Generates PDFs on device and shares them without cloud storage
class PdfService {

  /// Generate and share PDF for a customer sheet
  static Future<bool> generateAndSharePdf(
      CustomerSheet sheet,
      Customer customer,
      ) async {
    try {
      // Generate PDF document
      final PdfDocument document = await _createPdfDocument(sheet, customer);

      // Save PDF to temporary file
      final File pdfFile = await _savePdfToFile(document, sheet.title);

      // Dispose document to free memory
      document.dispose();

      // Share the PDF file
      await _sharePdfFile(pdfFile, sheet.title, customer.name);

      // Schedule cleanup after sharing
      _scheduleFileCleanup(pdfFile);

      return true;
    } catch (e) {
      print('Error generating PDF: $e');
      return false;
    }
  }

  /// Generate and save PDF to device storage
  static Future<String?> generateAndSavePdf(
      CustomerSheet sheet,
      Customer customer,
      ) async {
    try {
      // Generate PDF document
      final PdfDocument document = await _createPdfDocument(sheet, customer);

      // Save to device storage
      final File pdfFile = await _savePdfToDeviceStorage(document, sheet.title);

      // Dispose document
      document.dispose();

      return pdfFile.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Create PDF document with sheet data
  static Future<PdfDocument> _createPdfDocument(
      CustomerSheet sheet,
      Customer customer,
      ) async {
    // Create new PDF document
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    double yPosition = 0;

    // Add header
    yPosition = await _addHeader(graphics, yPosition);

    // Add customer information
    yPosition = await _addCustomerInfo(graphics, customer, yPosition);

    // Add sheet title
    yPosition = await _addSheetTitle(graphics, sheet.title, yPosition);

    // Add sheet data table
    yPosition = await _addDataTable(graphics, sheet, yPosition, page);

    // Add footer
    await _addFooter(graphics, page, sheet);

    return document;
  }

  /// Add header to PDF
  static Future<double> _addHeader(PdfGraphics graphics, double yPosition) async {
    // Company header
    graphics.drawString(
      AppStrings.appName,
      PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(0, 128, 0)), // Dark green
      bounds: Rect.fromLTWH(0, yPosition, 500, 30),
    );

    yPosition += 35;

    // Subtitle
    graphics.drawString(
      AppStrings.appTitle,
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      brush: PdfSolidBrush(PdfColor(128, 128, 128)), // Gray
      bounds: Rect.fromLTWH(0, yPosition, 500, 20),
    );

    yPosition += 30;

    // Horizontal line
    graphics.drawLine(
      PdfPen(PdfColor(200, 200, 200)),
      Offset(0, yPosition),
      Offset(500, yPosition),
    );

    return yPosition + 20;
  }

  /// Add customer information section
  static Future<double> _addCustomerInfo(
      PdfGraphics graphics,
      Customer customer,
      double yPosition,
      ) async {
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

    // Customer name
    graphics.drawString(
      '${AppStrings.customer}: ',
      boldFont,
      bounds: Rect.fromLTWH(0, yPosition, 100, 20),
    );
    graphics.drawString(
      customer.name,
      font,
      bounds: Rect.fromLTWH(100, yPosition, 400, 20),
    );

    yPosition += 20;

    // Phone number
    graphics.drawString(
      '${AppStrings.customerPhone}: ',
      boldFont,
      bounds: Rect.fromLTWH(0, yPosition, 100, 20),
    );
    graphics.drawString(
      customer.formattedPhoneNumber,
      font,
      bounds: Rect.fromLTWH(100, yPosition, 400, 20),
    );

    yPosition += 20;

    // Notes (if any)
    if (customer.hasNotes) {
      graphics.drawString(
        '${AppStrings.customerNotes}: ',
        boldFont,
        bounds: Rect.fromLTWH(0, yPosition, 100, 20),
      );

      // Handle multi-line notes
      final notes = customer.notes;
      if (notes.length > 60) {
        final lines = _splitTextIntoLines(notes, 60);
        for (int i = 0; i < lines.length && i < 3; i++) {
          graphics.drawString(
            i == 0 ? lines[i] : '    ${lines[i]}',
            font,
            bounds: Rect.fromLTWH(i == 0 ? 100 : 0, yPosition, 500, 20),
          );
          yPosition += 15;
        }
      } else {
        graphics.drawString(
          notes,
          font,
          bounds: Rect.fromLTWH(100, yPosition, 400, 20),
        );
        yPosition += 20;
      }
    }

    return yPosition + 10;
  }

  /// Add sheet title
  static Future<double> _addSheetTitle(
      PdfGraphics graphics,
      String title,
      double yPosition,
      ) async {
    graphics.drawString(
      '${AppStrings.sheet}: $title',
      PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(0, yPosition, 500, 25),
    );

    return yPosition + 35;
  }

  /// Add data table
  static Future<double> _addDataTable(
      PdfGraphics graphics,
      CustomerSheet sheet,
      double yPosition,
      PdfPage page,
      ) async {
    if (sheet.data.isEmpty) {
      graphics.drawString(
        'No data available',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        brush: PdfSolidBrush(PdfColor(128, 128, 128)),
        bounds: Rect.fromLTWH(0, yPosition, 500, 20),
      );
      return yPosition + 30;
    }

    // Create PDF grid
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: sheet.columnCount);

    // Add rows to grid
    for (int i = 0; i < sheet.rowCount; i++) {
      final PdfGridRow row = grid.rows.add();

      for (int j = 0; j < sheet.columnCount; j++) {
        final cellData = sheet.getCell(i, j);
        row.cells[j].value = cellData?.value ?? '';

        // Style numeric cells differently
        if (cellData?.isNumeric == true) {
          row.cells[j].style.textBrush = PdfSolidBrush(PdfColor(0, 0, 255)); // Blue
          row.cells[j].style.stringFormat = PdfStringFormat(
            alignment: PdfTextAlignment.right,
          );
        }
      }
    }

    // Style the grid
    grid.style.font = PdfStandardFont(PdfFontFamily.helvetica, 10);

    // Header style (first row)
    if (grid.rows.count > 0) {
      for (int i = 0; i < grid.columns.count; i++) {
        grid.rows[0].cells[i].style.backgroundBrush = PdfSolidBrush(PdfColor(211, 211, 211)); // Light gray
        grid.rows[0].cells[i].style.textBrush = PdfSolidBrush(PdfColor(0, 0, 0)); // Black
        grid.rows[0].cells[i].style.font = PdfStandardFont(
          PdfFontFamily.helvetica,
          10,
          style: PdfFontStyle.bold,
        );
      }
    }

    // Draw the grid
    final PdfLayoutResult result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, yPosition, page.getClientSize().width, 0),
    )!;

    return result.bounds.bottom + 20;
  }

  /// Add footer to PDF
  static Future<void> _addFooter(
      PdfGraphics graphics,
      PdfPage page,
      CustomerSheet sheet,
      ) async {
    final pageHeight = page.getClientSize().height;
    final footerY = pageHeight - 50;

    // Generation info
    graphics.drawString(
      'Generated on ${DateTime.now().toString().split('.')[0]}',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      brush: PdfSolidBrush(PdfColor(128, 128, 128)),
      bounds: Rect.fromLTWH(0, footerY, 300, 15),
    );

    // Sheet info
    graphics.drawString(
      'Sheet: ${sheet.title} | ${sheet.summary}',
      PdfStandardFont(PdfFontFamily.helvetica, 8),
      brush: PdfSolidBrush(PdfColor(128, 128, 128)),
      bounds: Rect.fromLTWH(0, footerY + 15, 500, 15),
    );
  }

  /// Save PDF to temporary file
  static Future<File> _savePdfToFile(PdfDocument document, String fileName) async {
    final List<int> bytes = await document.save();
    final directory = await getTemporaryDirectory();
    final sanitizedFileName = _sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${sanitizedFileName}_$timestamp.pdf');

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Save PDF to device storage (Downloads/Documents)
  static Future<File> _savePdfToDeviceStorage(PdfDocument document, String fileName) async {
    final List<int> bytes = await document.save();

    Directory directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final sanitizedFileName = _sanitizeFileName(fileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${sanitizedFileName}_$timestamp.pdf');

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Share PDF file
  static Future<void> _sharePdfFile(File file, String sheetTitle, String customerName) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sheet: $sheetTitle for Customer: $customerName',
      subject: '${AppStrings.appName} - $sheetTitle',
    );
  }

  /// Clean up temporary file after delay
  static void _scheduleFileCleanup(File file) {
    Future.delayed(const Duration(hours: 1), () {
      try {
        if (file.existsSync()) {
          file.deleteSync();
          print('Temporary PDF file cleaned up: ${file.path}');
        }
      } catch (e) {
        print('Error cleaning up PDF file: $e');
      }
    });
  }

  /// Sanitize filename for filesystem
  static String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// Split text into lines for multi-line display
  static List<String> _splitTextIntoLines(String text, int maxLength) {
    List<String> lines = [];
    String remaining = text;

    while (remaining.length > maxLength) {
      int splitIndex = maxLength;

      // Try to split at word boundary
      for (int i = maxLength; i > maxLength - 20 && i > 0; i--) {
        if (remaining[i] == ' ') {
          splitIndex = i;
          break;
        }
      }

      lines.add(remaining.substring(0, splitIndex));
      remaining = remaining.substring(splitIndex).trim();
    }

    if (remaining.isNotEmpty) {
      lines.add(remaining);
    }

    return lines;
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Check if PDF generation is supported on current platform
  static bool isPdfGenerationSupported() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get estimated PDF file size (rough calculation)
  static int estimatePdfSize(CustomerSheet sheet) {
    // Rough estimation based on content
    int baseSize = 10000; // 10KB base
    int cellDataSize = sheet.nonEmptyCellCount * 50; // ~50 bytes per cell
    return baseSize + cellDataSize;
  }

  /// Clean up all temporary PDF files
  static Future<void> cleanupTempPdfFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();

      for (var file in files) {
        if (file.path.endsWith('.pdf')) {
          await file.delete();
        }
      }

      print('All temporary PDF files cleaned up');
    } catch (e) {
      print('Error cleaning up temp PDF files: $e');
    }
  }
}