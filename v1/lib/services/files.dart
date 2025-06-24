import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class FileService {
  /// Picks a PDF file using the file picker
  /// Returns a FilePickerResult if successful, null otherwise
  Future<FilePickerResult?> pickPdfFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (e) {
      print('Error picking PDF file: $e');
      return null;
    }
  }

  /// Extracts text from a PDF file
  /// Returns the extracted text if successful, an error message otherwise
  Future<String> extractTextFromPdf(File file) async {
    try {
      // Load the PDF document
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extract text from all pages
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final StringBuffer textBuffer = StringBuffer();
      
      for (int i = 1; i <= document.pages.count; i++) {
        String pageText = extractor.extractText(startPageIndex: i - 1, endPageIndex: i - 1);
        textBuffer.write(pageText);
        textBuffer.write('\n\n'); // Add some spacing between pages
      }
      
      // Dispose the document
      document.dispose();
      
      String text = textBuffer.toString();
      
      // If text is empty, return a message
      if (text.trim().isEmpty) {
        return 'The PDF appears to be empty or contains only images that cannot be extracted as text.';
      }
      
      return text;
    } catch (e) {
      return 'Error extracting text from PDF: $e';
    }
  }
}
