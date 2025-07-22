import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfHelper {
  /// Pick a PDF file and extract its text content
  static Future<String?> pickPdfAndExtractText() async {
    try {
      print('📄 Starting PDF file picker...');
      
      // Pick PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 File selected: ${file.name}');
        
        if (file.path != null) {
          return await extractTextFromPdfPath(file.path!);
        } else if (file.bytes != null) {
          return await extractTextFromPdfBytes(file.bytes!);
        } else {
          print('❌ No file path or bytes available');
          return null;
        }
      } else {
        print('📄 No file selected');
        return null;
      }
    } catch (e) {
      print('❌ Error in pickPdfAndExtractText: $e');
      // DON'T RE-THROW - just return null to break the recursion
      return null;
    }
  }

  /// Extract text from PDF file path
  static Future<String> extractTextFromPdfPath(String filePath) async {
    try {
      print('📄 Reading file from path: $filePath');
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      print('📄 File read successfully, ${bytes.length} bytes');
      
      return await extractTextFromPdfBytes(bytes);
    } catch (e) {
      print('❌ Error reading PDF file: $e');
      // DON'T RE-THROW - return a simple error message
      return 'Error: Could not read PDF file - ${e.toString()}';
    }
  }

  /// Extract text from PDF bytes
  static Future<String> extractTextFromPdfBytes(List<int> bytes) async {
    try {
      print('📄 Starting PDF text extraction...');
      
      // Create PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Create text extractor and extract text
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      String extractedText = extractor.extractText();
      
      // Dispose document
      document.dispose();
      
      if (extractedText.trim().isEmpty) {
        return 'No text could be extracted from this PDF. The PDF might be image-based or password-protected.';
      }
      
      print('📄 Successfully extracted ${extractedText.length} characters');
      return cleanExtractedText(extractedText);
      
    } catch (e) {
      print('❌ Error extracting text from PDF: $e');
      // Return a simple error message without throwing
      return 'Error: Could not extract text from PDF - ${e.toString()}';
    }
  }

  /// Get a preview of the extracted text (first 500 characters)
  static String getTextPreview(String fullText, {int maxLength = 500}) {
    if (fullText.length <= maxLength) {
      return fullText;
    }
    return '${fullText.substring(0, maxLength)}...';
  }

  /// Clean and format extracted text
  static String cleanExtractedText(String text) {
    if (text.isEmpty) return text;
    
    try {
      return text
          .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Remove excessive line breaks
          .replaceAll(RegExp(r' +'), ' ') // Remove excessive spaces
          .trim();
    } catch (e) {
      print('❌ Error cleaning text: $e');
      return text; // Return original text if cleaning fails
    }
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    try {
      const suffixes = ['B', 'KB', 'MB', 'GB'];
      var i = 0;
      double size = bytes.toDouble();
      
      while (size >= 1024 && i < suffixes.length - 1) {
        size /= 1024;
        i++;
      }
      
      return '${size.toStringAsFixed(i == 0 ? 0 : 1)}${suffixes[i]}';
    } catch (e) {
      return 'Unknown size';
    }
  }
}