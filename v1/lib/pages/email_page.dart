import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:v1/services/tools.dart';
import 'package:v1/services/llm.dart';
import 'package:v1/widgets/setting_appbar.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  bool _isLoading = false;
  List<String> _emails = [];
  List<EmailSummary?> _emailSummaries = [];
  List<bool> _processingStatus = [];
  List<String> _errorMessages = [];
  List<String> _rawResponses = [];
  List<int> _processingTimes = [];
  int _currentProcessingIndex = -1;
  bool _fetchingMore = false;
  final int _maxEmails = 10;

  @override
  void initState() {
    super.initState();
    _fetchEmails();
  }

  Future<void> _fetchEmails() async {
    setState(() {
      _isLoading = true;
      _emails = [];
      _emailSummaries = [];
      _processingStatus = [];
      _errorMessages = [];
      _rawResponses = [];
      _processingTimes = [];
      _currentProcessingIndex = -1;
    });

    try {
      // Fetch up to 10 emails
      final emails = await readLatestEmails(count: _maxEmails);
      
      setState(() {
        _emails = emails;
        // Initialize summaries and processing status for each email
        _emailSummaries = List.generate(emails.length, (_) => null);
        _processingStatus = List.generate(emails.length, (_) => false);
        _errorMessages = List.generate(emails.length, (_) => '');
        _rawResponses = List.generate(emails.length, (_) => '');
        _processingTimes = List.generate(emails.length, (_) => 0);
      });

      // Start processing the first email
      if (emails.isNotEmpty) {
        _processNextEmail();
      }
    } catch (e) {
      setState(() {
        _errorMessages = ['Failed to fetch emails: $e'];
        _isLoading = false;
      });
    }
  }

  Future<void> _processNextEmail() async {
    // Find the next email to process
    int nextIndex = _currentProcessingIndex + 1;
    
    // If we've processed all emails, stop
    if (nextIndex >= _emails.length) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _currentProcessingIndex = nextIndex;
      _processingStatus[nextIndex] = true;
    });

    try {
      final email = _emails[nextIndex];
      final LlmService llmService = LlmService();
      
      final messages = [
        {
          'role': 'system',
          'content': 'You are an email processing assistant. Create a JSON object with the following fields:\n'
              '1. "title": A short 5-word title that captures the essence of the email\n'
              '2. "summary": A single sentence summary of the email content\n'
              '3. "category": Categorize as "important", "not important", or "advertising"\n\n'
              'Format your response as a valid JSON object. Example:\n'
              '{\n'
              '  "title": "Project deadline approaching soon",\n'
              '  "summary": "The team needs to submit the final project report by Friday.",\n'
              '  "category": "important"\n'
              '}\n'
              'Only output the JSON object, nothing else.'
        },
        {
          'role': 'user',
          'content': 'Please analyze this email:\n\n$email /no_think'
        }
      ];
      
      // Start timer
      final startTime = DateTime.now();
      String summary = '';
      await for (final event in llmService.getAIResponse(messages)) {
        if (event.type == LlmStreamEventType.fullResponse) {
          summary = event.content;
          break;
        }
      }
      // Calculate processing time in seconds
      final processingTime = DateTime.now().difference(startTime).inMilliseconds / 1000;
      
      try {
        final jsonSummary = jsonDecode(summary);
        final emailSummary = EmailSummary.fromJson(jsonSummary);
        
        setState(() {
          _emailSummaries[nextIndex] = emailSummary;
          _processingStatus[nextIndex] = false;
          _processingTimes[nextIndex] = processingTime.round();
        });
      } catch (jsonError) {
        setState(() {
          _errorMessages[nextIndex] = 'Error parsing response: $jsonError';
          _rawResponses[nextIndex] = summary;
          _processingStatus[nextIndex] = false;
          _processingTimes[nextIndex] = processingTime.round();
        });
      }
      
      // Process the next email
      _processNextEmail();
      
    } catch (e) {
      setState(() {
        _errorMessages[nextIndex] = 'Failed to summarize email: $e';
        _processingStatus[nextIndex] = false;
      });
      
      // Continue with the next email even if this one failed
      _processNextEmail();
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Colors.red;
      case 'advertising':
        return Colors.orange;
      case 'not important':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SettingAppBar(
        title: 'Email Summary',
        //onBackPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Email Summaries',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _fetchEmails,
                  tooltip: 'Refresh emails',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading && _emails.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_errorMessages.isNotEmpty && _emails.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessages.first),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchEmails,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            else if (_emails.isEmpty)
              const Center(
                child: Text('No emails found'),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _emails.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email ${index + 1}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Divider(),
                                  if (_processingStatus[index])
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (_errorMessages[index].isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            _errorMessages[index],
                                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                                          ),
                                        ),
                                        if (_rawResponses[index].isNotEmpty)
                                          ExpansionTile(
                                            title: const Text('View Raw LLM Response'),
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: SelectableText(_rawResponses[index]),
                                              ),
                                            ],
                                          ),
                                        if (_processingTimes[index] > 0)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Processing time: ${_processingTimes[index]} seconds',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ),
                                      ],
                                    )
                                  else if (_emailSummaries[index] != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor(_emailSummaries[index]!.category).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _getCategoryColor(_emailSummaries[index]!.category)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _emailSummaries[index]!.title,
                                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _getCategoryColor(_emailSummaries[index]!.category),
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Text(
                                                      _emailSummaries[index]!.category,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                _emailSummaries[index]!.summary,
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_processingTimes[index] > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                            child: Text(
                                              'Processing time: ${_processingTimes[index]} seconds',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  ExpansionTile(
                                    title: const Text('View Original Email'),
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(_emails[index]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Show processing status at the bottom
                    if (_currentProcessingIndex >= 0 && _currentProcessingIndex < _emails.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Processing email ${_currentProcessingIndex + 2} of ${_emails.length}...'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmailSummary {
  final String title;
  final String summary;
  final String category;

  EmailSummary({required this.title, required this.summary, required this.category});

  factory EmailSummary.fromJson(Map<String, dynamic> json) {
    return EmailSummary(
      title: json['title'] ?? 'No Title',
      summary: json['summary'] ?? 'No Summary',
      category: json['category'] ?? 'not important',
    );
  }
}
