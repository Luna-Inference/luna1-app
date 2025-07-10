import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

/// A data model for the server health status.
class ServerHealth {
  final String status;
  final String generationStatus;
  final String prefillSpeedTps;
  final String generationSpeedTps;

  ServerHealth({
    required this.status,
    required this.generationStatus,
    required this.prefillSpeedTps,
    required this.generationSpeedTps,
  });

  factory ServerHealth.fromJson(Map<String, dynamic> json) {
    return ServerHealth(
      status: json['status'] ?? 'Unknown',
      generationStatus: json['generation_status'] ?? 'N/A',
      prefillSpeedTps: (json['prefill_speed_tps'] ?? json['prompt_eval_speed_wps'])?.toString() ?? '-',
      generationSpeedTps: (json['generation_speed_tps'] ?? json['generation_speed_wps'])?.toString() ?? '-',
    );
  }

  factory ServerHealth.error(String errorMessage) {
      return ServerHealth(
          status: errorMessage,
          generationStatus: '',
          prefillSpeedTps: '-',
          generationSpeedTps: '-',
      );
  }
}

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
  final String _baseUrl = 'http://${AppConfig.llmIp}:1306';

  // Throttling: cache the last health response and its timestamp so that
  // multiple widgets calling [fetchServerHealth] within a short interval
  // reuse the same result instead of hitting the backend every time.
  static DateTime? _lastHealthFetch;
  static ServerHealth? _cachedHealth;

  /// Fetches the health status of the server.
  Future<ServerHealth> fetchServerHealth({Duration minInterval = const Duration(seconds: 10)}) async {
    // If we fetched recently, return the cached result to throttle requests.
    if (_lastHealthFetch != null &&
        _cachedHealth != null &&
        DateTime.now().difference(_lastHealthFetch!) < minInterval) {
      return _cachedHealth!;
    }

    final client = http.Client();
    try {
      final response = await client.get(Uri.parse('$_baseUrl/health'));
      ServerHealth result;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        result = ServerHealth.fromJson(data);
      } else {
        result = ServerHealth.error('Error: ${response.statusCode}');
      }
      // Update cache and timestamp on every attempt (success or error)
      _cachedHealth = result;
      _lastHealthFetch = DateTime.now();
      return result;
    } catch (e) {
      final errorResult = ServerHealth.error('Offline');
      _cachedHealth = errorResult;
      _lastHealthFetch = DateTime.now();
      return errorResult;
    } finally {
      client.close();
    }
  }

  /// Initiates a chat request and returns a stream of events.
  Stream<LlmStreamEvent> getAIResponse(List<Map<String, String>> messages) {
    final controller = StreamController<LlmStreamEvent>();
    final client = http.Client();

    final url = Uri.parse('$_baseUrl/v1/chat/completions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'luna-large',
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
