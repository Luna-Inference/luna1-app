import 'package:flutter/material.dart';
import 'package:luna_chat/applications/customer_success_chat.dart';

class UserDashboardApp extends StatefulWidget {
  const UserDashboardApp({super.key});

  @override
  State<UserDashboardApp> createState() => _UserDashboardAppState();
}

class _UserDashboardAppState extends State<UserDashboardApp> {
  bool _isChatVisible = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna Companion App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFFF7F7F7),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      home: Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        body: Stack(
          children: [
            // Main dashboard content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    SizedBox(height: 50),
                    
                    // Grid of cards
                    _buildGrid(),
                  ],
                ),
              ),
            ),
            
            // Chat toggle button
            _buildChatToggle(),
            
            // Chat widget
            if (_isChatVisible) _buildChatWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Luna Companion App',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'A suite of powerful, private, and local applications for your Luna device.',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 40,
          mainAxisSpacing: 40,
          childAspectRatio: 1.2,
          children: [
            _buildCodeVerterCard(),
            _buildAIPlatformerCard(),
          ],
        );
      },
    );
  }

  Widget _buildCodeVerterCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card image section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF222222),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFF666666),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Python',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFF444444),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'JavaScript',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  // Code input area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFF333333),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.all(15),
                      child: Text(
                        'Enter Python\\ncode here...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CodeVerter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Convert code between different languages seamlessly.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPlatformerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card image section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF1A1A40),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'AI Platformer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Card content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Platformer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Play a dynamic platformer where the world is generated by AI.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatToggle() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isChatVisible = !_isChatVisible;
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildChatWidget() {
    return Positioned(
      bottom: 90,
      right: 16,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 320,
        height: _isChatVisible ? 450 : 0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            child: Column(
              children: [
                // Chat header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF007AFF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Luna Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChatVisible = false;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Embedded chat widget - using the existing CustomerSuccessChatApp
                Expanded(
                  child: _ChatWidgetWrapper(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatWidgetWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomerSuccessChatApp();
  }
}