import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data'; // For Uint8List
// import 'package:path_provider/path_provider.dart'; // No longer needed for web playback
// import 'dart:io'; // No longer needed for web playback
import '../services/tts.dart'; // Assuming tts.dart is in lib/services/

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});

  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _synthesizeAndPlay() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter some text.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null; // Clear previous status
    });

    try {
      // Synthesize voice to get audio bytes
      final Uint8List audioBytes = await synthesizeVoice(
        textToSpeak: _textController.text,
        // outputFilePath: null, // Or omit if you don't want to save the file anywhere
        // To save on non-web platforms, you could conditionally provide a path here:
        // outputFilePath: kIsWeb ? null : '${(await getTemporaryDirectory()).path}/temp.ogg',
      );

      // Play audio from bytes
      await _audioPlayer.play(BytesSource(audioBytes));
      
      setState(() {
        _statusMessage = 'Playing audio...';
      });

    } catch (e) {
      print('Error in _synthesizeAndPlay: $e');
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to speak',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _synthesizeAndPlay,
                child: const Text('Synthesize and Play'),
              ),
            const SizedBox(height: 20),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Error:') 
                      ? Colors.red 
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


