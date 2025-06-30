import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class EmailSetup extends StatefulWidget {
  final String? clientSecretAssetPath;
  final String? clientSecretFilePath;
  final Function(String email, String accessToken)? onAuthSuccess;
  final Function(String error)? onAuthError;
  final bool showFullUI;
  final String buttonText;
  final Color? primaryColor;

  const EmailSetup({
    Key? key,
    this.clientSecretAssetPath = 'secrets/client_secret_962396646874-n36473pf4dldce1ono0a43qms8d7a87r.apps.googleusercontent.com.json',
    this.clientSecretFilePath = 'secrets/client_secret_962396646874-n36473pf4dldce1ono0a43qms8d7a87r.apps.googleusercontent.com.json',
    this.onAuthSuccess,
    this.onAuthError,
    this.showFullUI = true,
    this.buttonText = 'Authenticate Gmail',
    this.primaryColor = Colors.blue,
  }) : super(key: key);

  @override
  _EmailSetupState createState() => _EmailSetupState();
}

class _EmailSetupState extends State<EmailSetup>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _statusMessage = '';
  String? _authenticatedEmail;
  String? _accessToken;
  DateTime? _tokenExpiry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/gmail.readonly',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadClientSecrets() async {
    try {
      // Try to load from assets first
      if (widget.clientSecretAssetPath != null) {
        try {
          final String jsonString = await rootBundle.loadString(widget.clientSecretAssetPath!);
          return json.decode(jsonString);
        } catch (e) {
          print('Could not load from assets: $e');
        }
      }

      // Try to load from file system
      if (widget.clientSecretFilePath != null) {
        final file = File(widget.clientSecretFilePath!);
        if (await file.exists()) {
          final String jsonString = await file.readAsString();
          return json.decode(jsonString);
        }
      }

      throw Exception('Client secret file not found. Please add client_secret.json to your project.');
    } catch (e) {
      throw Exception('Failed to load client secrets: $e');
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading configuration...';
    });
    _animationController.forward();

    try {
      // Load client secrets
      final clientSecrets = await _loadClientSecrets();
      final clientId = auth.ClientId(
        clientSecrets['installed']['client_id'],
        clientSecrets['installed']['client_secret'],
      );

      setState(() {
        _statusMessage = 'Opening browser for authentication...';
      });

      // Use manual OAuth flow - no server binding required
      final auth.AuthClient client = await auth.clientViaUserConsentManual(
        clientId,
        _scopes,
        (String url) {
          print('=== GMAIL SMTP OAUTH URL ===');
          print('Please open this URL in your browser:');
          print(url);
          print('\n=== ATTEMPTING TO OPEN BROWSER ===');

          // Auto-open browser
          _openBrowser(url);
          
          // Update UI to show we're waiting for manual code entry
          setState(() {
            _statusMessage = 'Complete authentication in browser, then enter the code...';
          });
        },
        (String message) {
          print('OAuth Prompt: $message');
          // This function should return the authorization code
          return _getAuthCodeFromUser(message);
        },
      );

      setState(() {
        _statusMessage = 'Fetching Gmail profile...';
      });

      // Get Gmail profile and access token
      final GmailApi gmailApi = GmailApi(client);
      final profile = await gmailApi.users.getProfile('me');
      final accessToken = client.credentials.accessToken;

      // Store authentication data
      _authenticatedEmail = profile.emailAddress;
      _accessToken = accessToken.data;
      _tokenExpiry = accessToken.expiry;

      // Print SMTP credentials to console
      _printSmtpCredentials(profile.emailAddress!, accessToken);

      setState(() {
        _statusMessage = 'Authentication successful!';
        _isLoading = false;
      });

      // Call success callback
      widget.onAuthSuccess?.call(profile.emailAddress!, accessToken.data);

      // Close the HTTP client
      client.close();

    } catch (error) {
      final errorMessage = 'Authentication failed: $error';
      print('=== AUTHENTICATION ERROR ===');
      print(errorMessage);

      setState(() {
        _statusMessage = errorMessage;
        _isLoading = false;
      });

      widget.onAuthError?.call(errorMessage);
      _animationController.reverse();
    }
  }

  Future<String> _getAuthCodeFromUser(String message) async {
    final Completer<String> completer = Completer<String>();
    
    // Show dialog and wait for user input
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController codeController = TextEditingController();
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: widget.primaryColor),
              SizedBox(width: 12),
              Text('Enter Authorization Code'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete the authentication in your browser, then paste the authorization code here:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Authorization Code',
                    hintText: 'Paste the code from your browser',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      completer.complete(value.trim());
                      Navigator.of(context).pop();
                    }
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The browser should have opened automatically. Look for the authorization code on the page.',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                completer.complete(''); // Return empty string to cancel
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = codeController.text.trim();
                if (code.isNotEmpty) {
                  completer.complete(code);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
    
    return completer.future;
  }

  void _openBrowser(String url) {
    try {
      if (Platform.isWindows) {
        Process.run('start', [url], runInShell: true);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]);
      }
    } catch (e) {
      print('Could not auto-open browser: $e');
    }
  }

  void _printSmtpCredentials(String email, auth.AccessToken accessToken) {
    print('\n' + '=' * 50);
    print('🔐 GMAIL SMTP CREDENTIALS');
    print('=' * 50);
    print('📧 Email: $email');
    print('🔑 Access Token: ${accessToken.data}');
    print('⏰ Expires: ${accessToken.expiry}');
    print('\n📨 SMTP SERVER CONFIGURATION:');
    print('   Server: smtp.gmail.com');
    print('   Port: 587 (STARTTLS) or 465 (SSL)');
    print('   Username: $email');
    print('   Auth Method: OAuth2');
    print('   Access Token: ${accessToken.data}');
    print('\n💡 USAGE NOTES:');
    print('   • Use OAuth2 authentication with your SMTP client');
    print('   • Token expires at: ${accessToken.expiry}');
    print('   • Refresh token as needed for long-term use');
    print('=' * 50);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: Duration(seconds: 2),
        backgroundColor: widget.primaryColor,
      ),
    );
  }

  void _logout() {
    setState(() {
      _authenticatedEmail = null;
      _accessToken = null;
      _tokenExpiry = null;
      _statusMessage = '';
    });
    _animationController.reverse();
    print('=== LOGGED OUT ===');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showFullUI) {
      return _buildMinimalUI();
    }

    return _buildFullUI();
  }

  Widget _buildMinimalUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoading)
          CircularProgressIndicator(color: widget.primaryColor)
        else if (_authenticatedEmail != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Authenticated: $_authenticatedEmail'),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.logout, size: 20),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _authenticate,
            icon: Icon(Icons.email),
            label: Text(widget.buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        if (_statusMessage.isNotEmpty && _isLoading)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              _statusMessage,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildFullUI() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mail_lock,
                    color: widget.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gmail SMTP Authentication',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Get OAuth2 credentials for SMTP access',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Authentication Status
            if (_authenticatedEmail != null) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Successfully Authenticated',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                Text(
                                  _authenticatedEmail!,
                                  style: TextStyle(color: Colors.green[600]),
                                ),
                                if (_tokenExpiry != null)
                                  Text(
                                    'Token expires: ${_tokenExpiry!.toLocal()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToClipboard(_accessToken!, 'Access Token'),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Token'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copyToClipboard(_authenticatedEmail!, 'Email'),
                              icon: const Icon(Icons.email, size: 16),
                              label: const Text('Copy Email'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: widget.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // Authentication Button
              if (_isLoading) ...[
                CircularProgressIndicator(color: widget.primaryColor),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.login, size: 24),
                  label: Text(widget.buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_statusMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ],

            const SizedBox(height: 16),

            // Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'SMTP Configuration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Server: smtp.gmail.com\n'
                        '• Port: 587 (STARTTLS) or 465 (SSL)\n'
                        '• Auth: OAuth2 (use access token)\n'
                        '• Check console for full credentials',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
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

// Usage Examples:

// Full UI Widget
class FullUIExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gmail SMTP Auth')),
      body: Center(
        child: EmailSetup(
          onAuthSuccess: (email, token) {
            print('Success! Email: $email, Token: ${token.substring(0, 20)}...');
          },
          onAuthError: (error) {
            print('Error: $error');
          },
          primaryColor: Colors.red,
          buttonText: 'Connect Gmail',
        ),
      ),
    );
  }
}

// Minimal UI Widget
class MinimalUIExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Minimal Auth')),
      body: Center(
        child: EmailSetup(
          showFullUI: false,
          buttonText: 'Auth Gmail',
          onAuthSuccess: (email, token) {
            // Handle success
          },
        ),
      ),
    );
  }
}