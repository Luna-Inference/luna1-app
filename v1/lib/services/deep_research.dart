import 'dart:convert';

import 'package:v1/services/web_search.dart';

import 'llm.dart';


/// Example usage:
///   dart run deep_research.dart "What are the latest advances in quantum computing?" <TAVILY_API_KEY>
///
/// If no arguments are provided, you will be prompted for input.



/// Service for performing deep research using LLM for query analysis and decomposition.
class DeepResearchService {
  final LlmService llmService;

  DeepResearchService({required this.llmService});

  /// Phase 1: Analyze the user's query for intent, entities, and context.
  Future<Map<String, dynamic>> analyzeQuery(String query) async {
    final prompt = '''Analyze the following research query. Extract the intent, entities, and context as a JSON object.\n\nQuery: "$query"\n\nRespond ONLY with a valid JSON object.''';
    final messages = [
      {'role': 'system', 'content': 'You are an expert research assistant.'},
      {'role': 'user', 'content': prompt},
    ];
    final response = await _getFullLlmResponse(messages);
    try {
      return response.contains('{') ? jsonDecode(response.substring(response.indexOf('{'))) : {'intent': '', 'entities': [], 'context': ''};
    } catch (_) {
      return {'intent': '', 'entities': [], 'context': ''};
    }
  }

  /// Phase 2: Decompose the query into subtasks using LLM.
  Future<List<String>> decomposeQueryIntoSubtasks(String query, Map<String, dynamic> analysis) async {
    final prompt = '''Decompose the following research query into a list of concrete research subtasks.\n\nQuery: "$query"\n\nRespond ONLY with a numbered list.''';
    final messages = [
      {'role': 'system', 'content': 'You are an expert research assistant.'},
      {'role': 'user', 'content': prompt},
    ];
    final response = await _getFullLlmResponse(messages);
    // Parse numbered list
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final subtasks = <String>[];
    for (final line in lines) {
      final match = RegExp(r'^[0-9]+[\).\-:]\s*(.*)').firstMatch(line.trim());
      if (match != null) {
        subtasks.add(match.group(1)!.trim());
      } else {
        subtasks.add(line.trim());
      }
    }
    return subtasks.isNotEmpty ? subtasks : [query];
  }

  /// Phase 3: Generate targeted search queries for each subtask using LLM.
  Future<List<String>> generateSearchQueries(String subtask) async {
    final prompt = '''Generate 2-3 highly targeted web search queries to solve the following research subtask.\n\nSubtask: "$subtask"\n\nRespond ONLY with a numbered list.''';
    final messages = [
      {'role': 'system', 'content': 'You are an expert research assistant.'},
      {'role': 'user', 'content': prompt},
    ];
    final response = await _getFullLlmResponse(messages);
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final queries = <String>[];
    for (final line in lines) {
      final match = RegExp(r'^[0-9]+[\).\-:]\s*(.*)').firstMatch(line.trim());
      if (match != null) {
        queries.add(match.group(1)!.trim());
      } else {
        queries.add(line.trim());
      }
    }
    return queries.isNotEmpty ? queries : [subtask];
  }

  /// Phase 4: Execute web search for all queries and process results.
  Future<List<String>> executeSearches(List<String> queries, String tavilyApiKey) async {
    List<String> results = [];
    for (final query in queries) {
      try {
        final searchResult = await webSearchWithTavily(query, tavilyApiKey);
        results.add(searchResult['answer'] ?? '');
      } catch (e) {
        results.add('Search failed: $e');
      }
    }
    return results;
  }

  /// Phase 5: Synthesize knowledge using LLM (aggregate, summarize).
  Future<String> synthesizeKnowledge(List<String> knowledgeBase, String userQuery) async {
    // TODO: Replace with actual LLM call
    return knowledgeBase.join('\n---\n');
  }

  /// Phase 6: Generate a research report.
  String generateReport(String synthesizedKnowledge) {
    // Simple markdown formatting
    return '# Research Report\n\n$synthesizedKnowledge';
  }

  /// Full deep research pipeline
  Future<String> deepResearch(String userQuery, String tavilyApiKey) async {
    final analysis = await analyzeQuery(userQuery);
    final subtasks = await decomposeQueryIntoSubtasks(userQuery, analysis);
    List<String> allSearchQueries = [];
    for (final subtask in subtasks) {
      final queries = await generateSearchQueries(subtask);
      allSearchQueries.addAll(queries);
    }
    final searchResults = await executeSearches(allSearchQueries, tavilyApiKey);
    final synthesized = await synthesizeKnowledge(searchResults, userQuery);
    return generateReport(synthesized);
  }

  /// Helper: Get full response from LLM stream.
  Future<String> _getFullLlmResponse(List<Map<String, String>> messages) async {
    final stream = llmService.getAIResponse(messages);
    final buffer = StringBuffer();
    await for (final event in stream) {
      if (event.type == LlmStreamEventType.response || event.type == LlmStreamEventType.fullResponse) {
        buffer.write(event.content);
      }
    }
    return buffer.toString().trim();
  }
}


