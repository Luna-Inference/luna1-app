import 'package:flutter/material.dart';
import 'package:luna_chat/applications/customer_success_chat.dart';
import 'package:luna_chat/data/application_list.dart';

class UserDashboardApp extends StatefulWidget {
  const UserDashboardApp({super.key});

  @override
  State<UserDashboardApp> createState() => _UserDashboardAppState();
}

class _UserDashboardAppState extends State<UserDashboardApp> {
  bool _isChatVisible = true;
  late final Widget _chatWidget;

  @override
  void initState() {
    super.initState();
    _chatWidget = _ChatWidgetWrapper();
  }

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
        int crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 40,
          mainAxisSpacing: 40,
          childAspectRatio: 1.2,
          children: ApplicationList.applications
              .map((app) => _buildApplicationCard(app))
              .toList(),
        );
      },
    );
  }

  Widget _buildApplicationCard(LunaApplication app) {
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
                color: app.color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Center(
                child: Icon(
                  app.icon,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Card content
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (app.isComingSoon) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: app.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: app.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      app.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
        width: 450,
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
                
                // Embedded chat widget - using the persistent chat widget
                Expanded(
                  child: _chatWidget,
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