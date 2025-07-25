import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:luna_chat/config.dart';
import 'package:luna_chat/data/luna_ip_address.dart';

/// An enum to represent the different types of events in the LLM stream.
enum LlmStreamEventType {
  thinking, // Content inside <think> tags
  token, // Each streaming token/chunk of visible response
  done, // Stream completed successfully
  error, // Error occurred
}

/// A data model for events coming from the LLM response stream.
class LlmStreamEvent {
  final LlmStreamEventType type;
  final String content;

  LlmStreamEvent({required this.type, required this.content});

  @override
  String toString() => 'LlmStreamEvent(type: $type, content: "$content")';
}

/// A service class to handle all interactions with the LLM backend.
class LlmService {
  final String _baseUrl = 'http://${LunaPort.lunaIpAddress}:${LunaPort.llm}';

  // Keep track of active request to allow cancellation
  http.Client? _activeClient;

  /// Sends a message to the LLM and returns a stream of response events.
  ///
  /// [messages] should be a list of conversation messages in the format:
  /// [{'role': 'system', 'content': 'You are a helpful assistant'}, ...]
  Stream<LlmStreamEvent> sendMessage(List<Map<String, String>> messages) {
    // Cancel any existing request
    _activeClient?.close();

    final controller = StreamController<LlmStreamEvent>();
    final client = http.Client();
    _activeClient = client;

    final url = Uri.parse('$_baseUrl/v1/chat/completions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'luna-small',
      'messages': messages,
      'stream': true,
      'temperature': 0.7,
      'max_tokens': 2048,
    });

    final request =
        http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = body;

    StringBuffer responseBuffer = StringBuffer();
    StringBuffer streamBuffer = StringBuffer();
    StringBuffer thinkBuffer = StringBuffer();
    bool inThinkBlock = false;

    client
        .send(request)
        .then((streamedResponse) {
          if (streamedResponse.statusCode != 200) {
            controller.add(
              LlmStreamEvent(
                type: LlmStreamEventType.error,
                content:
                    'API Error: ${streamedResponse.statusCode} - ${streamedResponse.reasonPhrase}',
              ),
            );
            controller.close();
            client.close();
            return;
          }

          streamedResponse.stream
              .transform(utf8.decoder)
              .listen(
                (chunkData) {
                  try {
                    streamBuffer.write(chunkData);
                    String currentData = streamBuffer.toString();
                    List<String> lines = currentData.split('\n');
                    streamBuffer.clear();

                    // Keep incomplete line in buffer
                    if (lines.isNotEmpty && !currentData.endsWith('\n')) {
                      streamBuffer.write(lines.removeLast());
                    }

                    for (var line in lines) {
                      line = line.trim();
                      if (line.isEmpty || line == 'data: [DONE]') {
                        if (line == 'data: [DONE]') {
                          // Stream completed
                          controller.add(
                            LlmStreamEvent(
                              type: LlmStreamEventType.done,
                              content: responseBuffer.toString(),
                            ),
                          );
                        }
                        continue;
                      }

                      if (line.startsWith('data: ')) {
                        line = line.substring(6);
                      }

                      try {
                        final Map<String, dynamic> data = jsonDecode(line);
                        final choices = data['choices'] as List?;

                        if (choices == null || choices.isEmpty) continue;

                        final delta =
                            choices[0]['delta'] as Map<String, dynamic>?;
                        final deltaContent = delta?['content'] as String?;

                        if (deltaContent == null || deltaContent.isEmpty)
                          continue;

                        // Process content, handling thinking blocks
                        _processContent(
                          deltaContent,
                          inThinkBlock,
                          thinkBuffer,
                          responseBuffer,
                          controller,
                          (newInThinkState) => inThinkBlock = newInThinkState,
                        );
                      } catch (e) {
                        // Ignore JSON parse errors for incomplete lines
                        continue;
                      }
                    }
                  } catch (e) {
                    controller.add(
                      LlmStreamEvent(
                        type: LlmStreamEventType.error,
                        content: 'Processing error: $e',
                      ),
                    );
                  }
                },
                onDone: () {
                  // No need to emit remaining thinking content since we stream it incrementally

                  // Ensure we emit done event if not already emitted
                  if (!controller.isClosed) {
                    controller.add(
                      LlmStreamEvent(
                        type: LlmStreamEventType.done,
                        content: responseBuffer.toString(),
                      ),
                    );
                  }
                  controller.close();
                  client.close();
                  if (_activeClient == client) _activeClient = null;
                },
                onError: (e) {
                  controller.add(
                    LlmStreamEvent(
                      type: LlmStreamEventType.error,
                      content: 'Stream error: $e',
                    ),
                  );
                  controller.close();
                  client.close();
                  if (_activeClient == client) _activeClient = null;
                },
              );
        })
        .catchError((e) {
          controller.add(
            LlmStreamEvent(
              type: LlmStreamEventType.error,
              content: 'Request error: $e',
            ),
          );
          controller.close();
          client.close();
          if (_activeClient == client) _activeClient = null;
        });

    return controller.stream;
  }

  /// Process thinking blocks and emit appropriate events
  void _processContent(
    String deltaContent,
    bool inThinkBlock,
    StringBuffer thinkBuffer,
    StringBuffer responseBuffer,
    StreamController<LlmStreamEvent> controller,
    Function(bool) setInThinkState,
  ) {
    String remainingContent = deltaContent;

    while (remainingContent.isNotEmpty) {
      if (inThinkBlock) {
        // We're inside a thinking block, look for closing tag
        int endTagIndex = remainingContent.indexOf('</think>');
        if (endTagIndex != -1) {
          // Found end of thinking block - process content up to the closing tag
          String thinkContent = remainingContent.substring(0, endTagIndex);
          if (thinkContent.isNotEmpty) {
            thinkBuffer.write(thinkContent);
            // Emit the incremental thinking content
            controller.add(
              LlmStreamEvent(
                type: LlmStreamEventType.thinking,
                content: thinkBuffer.toString(),
              ),
            );
          }

          remainingContent = remainingContent.substring(
            endTagIndex + '</think>'.length,
          );
          setInThinkState(false);
          // Don't clear thinkBuffer yet - we'll clear it when we start the next thinking block
        } else {
          // Still in thinking block, stream the content incrementally
          thinkBuffer.write(remainingContent);
          controller.add(
            LlmStreamEvent(
              type: LlmStreamEventType.thinking,
              content: thinkBuffer.toString(),
            ),
          );
          remainingContent = '';
        }
      } else {
        // We're outside thinking block, look for opening tag
        int startTagIndex = remainingContent.indexOf('<think>');
        if (startTagIndex != -1) {
          // Found start of thinking block
          String textBeforeThink = remainingContent.substring(0, startTagIndex);
          if (textBeforeThink.isNotEmpty) {
            responseBuffer.write(textBeforeThink);
            controller.add(
              LlmStreamEvent(
                type: LlmStreamEventType.token,
                content: textBeforeThink,
              ),
            );
          }
          remainingContent = remainingContent.substring(
            startTagIndex + '<think>'.length,
          );
          setInThinkState(true);
          // Clear thinking buffer when starting new thinking block
          thinkBuffer.clear();
        } else {
          // No thinking block, all content is visible
          responseBuffer.write(remainingContent);
          controller.add(
            LlmStreamEvent(
              type: LlmStreamEventType.token,
              content: remainingContent,
            ),
          );
          remainingContent = '';
        }
      }
    }
  }

  /// Cancel any ongoing request
  void cancelCurrentRequest() {
    _activeClient?.close();
    _activeClient = null;
  }

  /// Dispose resources
  void dispose() {
    cancelCurrentRequest();
  }

  // Legacy method for backward compatibility
  @Deprecated('Use sendMessage instead')
  Stream<LlmStreamEvent> getAIResponse(List<Map<String, String>> messages) {
    return sendMessage(messages);
  }
}
