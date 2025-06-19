import '../deep_research.dart';
import '../llm.dart';
import 'dart:async';
import 'dart:convert';


// Mock LlmService that returns a canned response
class MockLlmService implements LlmService {
  @override
  Stream<LlmStreamEvent> getAIResponse(List<Map<String, String>> messages) async* {
    // Detect which prompt is being used and return a suitable fake response
    final userPrompt = messages.last['content'] ?? '';
    if (userPrompt.contains('Extract the intent')) {
      yield LlmStreamEvent(
        type: LlmStreamEventType.fullResponse,
        content: '{"intent": "research", "entities": ["quantum computing"], "context": "latest advances"}',
      );
    } else {
      yield LlmStreamEvent(type: LlmStreamEventType.fullResponse, content: '[]');
    }
  }
  // Add stubs for any other required methods if needed

  @override
  Future<ServerHealth> fetchServerHealth() async {
    // Return a dummy ServerHealth object
    return ServerHealth(
      status: 'ok',
      generationStatus: 'ok',
      promptEvalSpeedWps: '-',
      generationSpeedWps: '-',
    );
  }
}

void main() async {
  final mockLlm = MockLlmService();
  final service = DeepResearchService(llmService: mockLlm);

  final query = 'What are the latest advances in quantum computing?';
  final analysis = await service.analyzeQuery(query);
  print('Analysis result:');
  print(jsonEncode(analysis));
}
