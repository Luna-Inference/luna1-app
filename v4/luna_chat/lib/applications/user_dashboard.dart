import 'package:flutter/material.dart';
import 'package:luna_chat/applications/customer_success_chat.dart';
import 'package:luna_chat/data/application_list.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/widgets/application_card.dart';

class UserDashboardApp extends StatefulWidget {
  const UserDashboardApp({super.key});

  @override
  State<UserDashboardApp> createState() => _UserDashboardAppState();
}

class _UserDashboardAppState extends State<UserDashboardApp> {
  // State variables
  bool _isChatVisible = true;
  late final Widget _chatWidget;

  // Constants for chat widget
  static const double _chatWidth = 450.0;
  static const double _chatHeight = 450.0;
  static const double _chatSpacing = 16.0; // Gap between FAB and chat widget

  @override
  void initState() {
    super.initState();
    _chatWidget = _ChatWidgetWrapper();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dashboardBackground,
      body: _buildMainContent(),
      floatingActionButton: _buildFloatingChatSection(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Main scrollable content of the dashboard
  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 50),
            _buildGrid(),
            // Add bottom padding to prevent FAB overlap
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Floating chat section that includes both FAB and chat widget
  Widget _buildFloatingChatSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Chat widget appears above the FAB when visible
        if (_isChatVisible) ...[
          _buildAttachedChatWidget(),
          const SizedBox(height: _chatSpacing),
        ],
        // Floating action button
        FloatingActionButton(
          onPressed: _toggleChatVisibility,
          backgroundColor: chatBlue,
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Toggle chat visibility
  void _toggleChatVisibility() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
  }

  /// Dashboard header with title and subtitle
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Luna Companion App',
          style: dashboardTitle.copyWith(color: primaryText),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'A suite of powerful, private, and local applications for your Luna device.',
          style: dashboardSubtitle.copyWith(color: secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Responsive grid of application cards
  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine columns based on screen width
        final int crossAxisCount = _calculateGridColumns(constraints.maxWidth);
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 40,
          mainAxisSpacing: 40,
          childAspectRatio: 1.2,
          children: ApplicationList.applications
              .map((app) => ApplicationCard(app: app))
              .toList(),
        );
      },
    );
  }

  /// Calculate number of grid columns based on screen width
  int _calculateGridColumns(double screenWidth) {
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 2;
    return 1;
  }



  /// Chat widget that's physically attached to the FAB
  Widget _buildAttachedChatWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _chatWidth,
      height: _isChatVisible ? _chatHeight : 0,
      decoration: _buildChatDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildChatHeader(),
            _buildChatContent(),
          ],
        ),
      ),
    );
  }

  /// Chat widget decoration with shadow
  BoxDecoration _buildChatDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 25,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Chat header with title and close button
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: chatBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Luna Assistant',
            style: chatAppBarTitle.copyWith(color: Colors.white),
          ),
          GestureDetector(
            onTap: _toggleChatVisibility,
            child: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Chat content area
  Widget _buildChatContent() {
    return Expanded(
      child: _chatWidget,
    );
  }
}

class _ChatWidgetWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomerSuccessChatApp();
  }
}