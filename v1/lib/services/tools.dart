import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:enough_mail/enough_mail.dart';

/// Performs a web search and returns the top result as a string.
///
/// Parameters:
///   - query (String): The search term.
/// Returns:
///   - String: The search result.
Future<String> search(String query) async {
  print('performing tavily search');
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
Future<void> sendEmail({required String recipient, String subject = 'Message from Luna', required String body}) async {
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

/// Returns today's date as a formatted string (YYYY-MM-DD).
String getTodayDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Adds a new line of text to a specified Notion page.
///
/// Parameters:
///   - content (String): The text content to add to the Notion page.
/// Returns:
///   - Future<String>: A confirmation message.
Future<String> addNote(String content) async {
  print('adding note to notion');
  final apiKey = dotenv.env['NOTION_API_KEY'] ?? '';
  final pageId = dotenv.env['NOTION_NOTES_PAGE_ID'] ?? '';

  if (apiKey.isEmpty) {
    throw StateError('NOTION_API_KEY not set in environment.');
  }
  if (pageId.isEmpty) {
    throw StateError('NOTION_NOTES_PAGE_ID not set in environment.');
  }

  final uri = Uri.parse('https://api.notion.com/v1/blocks/$pageId/children');

  final response = await http.patch(  // Changed from post to patch
    uri,
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Notion-Version': '2022-06-28',
    },
    body: jsonEncode({
      'children': [
        {
          'object': 'block',
          'type': 'paragraph',
          'paragraph': {
            'rich_text': [
              {
                'type': 'text',
                'text': {
                  'content': content,
                },
              },
            ],
          },
        },
      ],
    }),
  );

  if (response.statusCode == 200) {
    return 'Successfully added note to Notion.';
  } else {
    throw http.ClientException('Notion API error: ${response.statusCode} ${response.body}');
  }
}

/// Reads the latest `count` email messages from the configured mailbox.
///
/// Environment variables required (in `.env`):
///   IMAP_HOST          – e.g. "imap.gmail.com"
///   IMAP_PORT          – e.g. "993" (default 993 for SSL, 143 for plain)
///   IMAP_USERNAME      – login / full email
///   IMAP_PASSWORD      – password or app-password
///   IMAP_USE_SSL       – optional, "true" (default) / "false"
///
/// Returns a list of plain-text bodies (newest first).
Future<List<String>> readLatestEmails({int count = 10}) async {
  final host = dotenv.env['IMAP_HOST'] ?? '';
  final portStr = dotenv.env['IMAP_PORT'] ?? '';
  final username = dotenv.env['IMAP_USERNAME'] ?? '';
  final password = dotenv.env['IMAP_PASSWORD'] ?? '';
  final useSsl = (dotenv.env['IMAP_USE_SSL'] ?? 'true').toLowerCase() != 'false';

  if (host.isEmpty || username.isEmpty || password.isEmpty) {
    throw StateError('IMAP_HOST, IMAP_USERNAME or IMAP_PASSWORD not set in .env');
  }

  final port = int.tryParse(portStr.isEmpty ? (useSsl ? '993' : '143') : portStr) ?? (useSsl ? 993 : 143);

  final client = ImapClient(isLogEnabled: false);
  try {
    await client.connectToServer(host, port, isSecure: useSsl);
    await client.login(username, password);
    await client.selectInbox();

    final fetchResult = await client.fetchRecentMessages(
      messageCount: count,
      criteria: 'BODY.PEEK[]',
    );

    final bodies = <String>[];
    for (final message in fetchResult.messages) {
      final body = message.decodeTextPlainPart() ?? message.decodeTextHtmlPart() ?? '';
      bodies.add(body);
    }

    return bodies;
  } finally {
    try {
      await client.logout();
    } catch (_) {}
  }
}