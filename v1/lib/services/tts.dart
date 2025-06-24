import 'dart:convert';
import 'dart:io'; // Used only if outputFilePath is provided
import 'dart:typed_data'; // For Uint8List
import 'package:http/http.dart' as http;

const String _baseUrl = "http://100.76.203.80:8848";

/// Synthesizes audio from text using a remote TTS service.
///
/// Returns the audio data as [Uint8List].
/// Optionally saves the audio to [outputFilePath] if provided.
///
/// [textToSpeak]: The text to be converted to speech.
/// [outputFilePath]: Optional. The path where the generated audio file will be saved.
/// [audioFormat]: The desired audio format (e.g., "opus", "mp3"). Defaults to "opus".
///
/// Throws an [Exception] if the API request fails.
Future<Uint8List> synthesizeVoice({
  required String textToSpeak,
  String? outputFilePath, // Made optional
  String audioFormat = "opus",
}) async {
  final url = Uri.parse('$_baseUrl/api/v1/synthesise');

  final payload = {
    "text": textToSpeak,
    "audio_format": audioFormat,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {

      if (outputFilePath != null && outputFilePath.isNotEmpty) {
        // Save to file only if path is provided (primarily for non-web or debugging)
        try {
          final file = File(outputFilePath);
          await file.writeAsBytes(response.bodyBytes);
          print('Saved audio to $outputFilePath');
        } catch (e) {
          // Log file saving error, but don't let it stop returning bytes
          print('Error saving audio file to $outputFilePath: $e');
        }
      }
      return response.bodyBytes;
    } else {
      throw Exception(
          'Failed to synthesize voice: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Error during voice synthesis: $e');
    rethrow; // Rethrow the exception to allow calling code to handle it
  }
}

// Example usage (can be run directly if this file is the entry point):
// void main() async {
//   try {
//     // Example 1: Get bytes and optionally save
//     final audioBytes = await synthesizeVoice(
//       textToSpeak: "Hello from Dart! This is a test.",
//       outputFilePath: "dart_output.ogg", // Optional: saves the file
//     );
//     print('Received ${audioBytes.length} bytes of audio data.');

//     // Example 2: Get bytes without saving to file (e.g., for web)
//     // final webAudioBytes = await synthesizeVoice(
//     //   textToSpeak: "Hello for web!",
//     // );
//     // print('Received ${webAudioBytes.length} bytes for web playback.');

//   } catch (e) {
//     print("Error in example usage: $e");
//   }
// }

