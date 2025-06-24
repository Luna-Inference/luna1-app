import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Performs a web search and returns the top result as a string.
///
/// Parameters:
///   - query (String): The search term.
/// Returns:
///   - String: The search result.
Future<String> search(String query) async {
  final apiKey = dotenv.env['TAVILY_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    throw StateError('TAVILY_API_KEY not set in environment.');
  }

    final uri = Uri.parse('https://api.tavily.com/search');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      'query': query,
      'max_results': 1,
    }),
  );
  if (response.statusCode != 200) {
    throw http.ClientException('Tavily API error: \\${response.statusCode} \\${response.body}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  if (data['results'] is List && data['results'].isNotEmpty) {
    final first = data['results'][0] as Map<String, dynamic>;
    return first['content'] ?? first['url'] ?? first.toString();
  }
  return '';
}

/// Sends an email to a specified recipient.
///
/// Parameters:
///   - recipient (String): The email address to send to.
///   - subject (String): The subject of the email.
///   - body (String): The body of the email.
/// Returns:
///   - None
Future<void> sendEmail({required String recipient, required String subject, required String body}) async {
  final username = dotenv.env['SMTP_USERNAME'] ?? '';
  final password = dotenv.env['SMTP_PASSWORD'] ?? '';
  if (username.isEmpty || password.isEmpty) {
    throw StateError('SMTP_USERNAME or SMTP_PASSWORD not set in .env');
  }

  // Configure server (example uses Gmail; adjust host if needed)
  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Luna App')
    ..recipients.add(recipient)
    ..subject = subject
    ..text = body;

  await send(message, smtpServer);
}

