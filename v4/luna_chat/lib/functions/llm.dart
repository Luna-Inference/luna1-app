import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luna_chat/data/luna_ip_address.dart';

/// An enum to represent the different types of events in the LLM stream.
enum LlmStreamEventType { thinking, response, fullResponse, error }

/// A data model for events coming from the LLM response stream.
class LlmStreamEvent {
  final LlmStreamEventType type;
  final String content;

  LlmStreamEvent({required this.type, required this.content});
}

/// A service class to handle all interactions with the LLM backend.
class LlmService {
  final String _baseUrl = 'http://$lunaIpAddress:1309';

  /// Initiates a chat request and returns a stream of events.
  Stream<LlmStreamEvent> getAIResponse(List<Map<String, String>> messages) {
    final controller = StreamController<LlmStreamEvent>();
    final client = http.Client();

    final url = Uri.parse('$_baseUrl/v1/chat/completions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'luna-small',
      'messages': messages,
      'stream': true,
    });

    final request = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = body;

    StringBuffer responseContentBuffer = StringBuffer();
    StringBuffer thinkingContentBuffer = StringBuffer();
    bool inThinkBlock = false;
    StringBuffer streamBuffer = StringBuffer();

    client.send(request).then((streamedResponse) {
      if (streamedResponse.statusCode != 200) {
        controller.add(LlmStreamEvent(type: LlmStreamEventType.error, content: 'API Error: ${streamedResponse.statusCode}'));
        controller.close();
        client.close();
        return;
      }

      streamedResponse.stream.transform(utf8.decoder).listen((chunkData) {
        streamBuffer.write(chunkData);
        String currentData = streamBuffer.toString();
        List<String> lines = currentData.split('\n');
        streamBuffer.clear();
        if (lines.isNotEmpty && !currentData.endsWith('\n')) {
          streamBuffer.write(lines.removeLast());
        }

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty || line == 'data: [DONE]') continue;
          if (line.startsWith('data: ')) {
            line = line.substring(6);
          }

          try {
            final Map<String, dynamic> data = jsonDecode(line);
            final String deltaContent = data['choices'][0]['delta']?['content'] ?? '';
            if (deltaContent.isEmpty) continue;

            String remainingDeltaContent = deltaContent;
            while (remainingDeltaContent.isNotEmpty) {
              if (inThinkBlock) {
                int endTagIndex = remainingDeltaContent.indexOf('</think>');
                if (endTagIndex != -1) {
                  thinkingContentBuffer.write(remainingDeltaContent.substring(0, endTagIndex));
                  remainingDeltaContent = remainingDeltaContent.substring(endTagIndex + '</think>'.length);
                  inThinkBlock = false;
                } else {
                  thinkingContentBuffer.write(remainingDeltaContent);
                  remainingDeltaContent = '';
                }
              } else {
                int startTagIndex = remainingDeltaContent.indexOf('<think>');
                if (startTagIndex != -1) {
                  String textForResponse = remainingDeltaContent.substring(0, startTagIndex);
                  if (textForResponse.isNotEmpty) {
                    responseContentBuffer.write(textForResponse);
                  }
                  remainingDeltaContent = remainingDeltaContent.substring(startTagIndex + '<think>'.length);
                  inThinkBlock = true;
                } else {
                  responseContentBuffer.write(remainingDeltaContent);
                  remainingDeltaContent = '';
                }
              }
            }

            if (thinkingContentBuffer.isNotEmpty) {
              controller.add(LlmStreamEvent(type: LlmStreamEventType.thinking, content: thinkingContentBuffer.toString()));
            }
            if (responseContentBuffer.isNotEmpty) {
              controller.add(LlmStreamEvent(type: LlmStreamEventType.response, content: responseContentBuffer.toString()));
            }

          } catch (e) {
            // Ignore JSON parse errors for incomplete lines
          }
        }
      }, onDone: () {
        controller.add(LlmStreamEvent(type: LlmStreamEventType.fullResponse, content: responseContentBuffer.toString()));
        controller.close();
        client.close();
      }, onError: (e) {
        controller.add(LlmStreamEvent(type: LlmStreamEventType.error, content: 'Stream error: $e'));
        controller.close();
        client.close();
      });
    }).catchError((e) {
      controller.add(LlmStreamEvent(type: LlmStreamEventType.error, content: 'Request error: $e'));
      controller.close();
      client.close();
    });

    return controller.stream;
  }
}
