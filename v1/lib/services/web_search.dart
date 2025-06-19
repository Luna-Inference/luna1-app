import 'dart:convert';
import 'package:http/http.dart' as http;

/// Performs a web search using the Tavily API.
/// [query] is the search string.
/// [apiKey] is your Tavily API key.
/// Returns a Map with the search results or throws an error.
Future<Map<String, dynamic>> webSearchWithTavily(String query, String apiKey) async {
  final url = Uri.parse('https://api.tavily.com/search');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'query': query,
      'search_depth': 'basic', // or 'advanced' if you want more detail
      'include_answer': true,
      'include_raw_content': false,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Tavily search failed: \\${response.statusCode} \\${response.body}');
  }
}
