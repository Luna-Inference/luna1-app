import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';

class LunaChatApp extends StatefulWidget {
  // Chat Configuration
  final String chatTitle;
  final bool showAppBar;
  final List<Widget>? appBarActions;
  
  // User Configuration
  final ChatUser currentUser;
  final ChatUser? otherUser;
  
  // Message Configuration
  final List<ChatMessage> initialMessages;
  final Function(ChatMessage)? onSend;
  final Function(ChatMessage)? onMessageTap;
  final Function(ChatMessage)? onMessageLongPress;
  
  // Input Configuration
  final String inputHint;
  final bool showSendButton;
  final bool showAttachmentButton;
  final bool showMicrophoneButton;
  final int? maxInputLength;
  final TextInputType inputType;
  final bool autocorrect;
  final bool enableSuggestions;
  
  // Appearance Configuration
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final Color? messageBackgroundColor;
  final Color? textColor;
  final double? messageRadius;
  final double? inputRadius;
  final EdgeInsets? messagePadding;
  final EdgeInsets? inputPadding;
  
  // Typography Configuration
  final TextStyle? messageTextStyle;
  final TextStyle? inputTextStyle;
  final TextStyle? timeTextStyle;
  
  // Bubble Configuration
  final bool showUserAvatar;
  final bool showOtherUsersAvatar;
  final bool showCurrentUserAvatar;
  final double? avatarSize;
  final bool showUserName;
  final bool showMessageTime;
  final bool showMessageStatus;
  final MessageListOptions? messageListOptions;
  final QuickReplyOptions? quickReplyOptions;
  
  // Advanced Features
  final bool enableSwipeToReply;
  final bool enableTypingIndicator;
  final bool enableReadReceipts;
  final bool enableMessageReactions;
  final bool scrollToBottomOnSend;
  final Duration? typingIndicatorDelay;

  const LunaChatApp({
    Key? key,
    this.chatTitle = 'Chat',
    this.showAppBar = true,
    this.appBarActions,
    required this.currentUser,
    this.otherUser,
    this.initialMessages = const [],
    this.onSend,
    this.onMessageTap,
    this.onMessageLongPress,
    this.inputHint = 'Type a message...',
    this.showSendButton = true,
    this.showAttachmentButton = false,
    this.showMicrophoneButton = false,
    this.maxInputLength,
    this.inputType = TextInputType.multiline,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.messageBackgroundColor,
    this.textColor,
    this.messageRadius,
    this.inputRadius,
    this.messagePadding,
    this.inputPadding,
    this.messageTextStyle,
    this.inputTextStyle,
    this.timeTextStyle,
    this.showUserAvatar = true,
    this.showOtherUsersAvatar = true,
    this.showCurrentUserAvatar = false,
    this.avatarSize,
    this.showUserName = true,
    this.showMessageTime = true,
    this.showMessageStatus = true,
    this.messageListOptions,
    this.quickReplyOptions,
    this.enableSwipeToReply = false,
    this.enableTypingIndicator = false,
    this.enableReadReceipts = false,
    this.enableMessageReactions = false,
    this.scrollToBottomOnSend = true,
    this.typingIndicatorDelay,
  }) : super(key: key);

  @override
  State<LunaChatApp> createState() => _LunaChatAppState();
}

class _LunaChatAppState extends State<LunaChatApp> {
  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];
  
  @override
  void initState() {
    super.initState();
    messages = [...widget.initialMessages];
  }

  void onSend(ChatMessage message) {
    setState(() {
      messages.insert(0, message);
    });
    
    if (widget.onSend != null) {
      widget.onSend!(message);
    }
    
    // Simulate typing indicator for demo
    if (widget.enableTypingIndicator && widget.otherUser != null) {
      _simulateTypingResponse(message);
    }
  }

  void _simulateTypingResponse(ChatMessage userMessage) {
    setState(() {
      typingUsers.add(widget.otherUser!);
    });

    Future.delayed(widget.typingIndicatorDelay ?? const Duration(seconds: 2), () {
      setState(() {
        typingUsers.clear();
        // Add a response message
        messages.insert(0, ChatMessage(
          text: _generateResponse(userMessage.text),
          user: widget.otherUser!,
          createdAt: DateTime.now(),
        ));
      });
    });
  }

  String _generateResponse(String userText) {
    // Simple response generation for demo
    final responses = [
      "That's interesting! Tell me more.",
      "I understand what you mean.",
      "Thanks for sharing that with me.",
      "How do you feel about that?",
      "That sounds great!",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? whiteAccent,
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          widget.chatTitle,
          style: headingText.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: widget.primaryColor ?? buttonColor,
        foregroundColor: widget.textColor ?? whiteAccent,
        elevation: 0,
        actions: widget.appBarActions,
      ) : null,
      body: DashChat(
        currentUser: widget.currentUser,
        onSend: onSend,
        messages: messages,
        typingUsers: widget.enableTypingIndicator ? typingUsers : [],
        
        // Message Configuration
        messageOptions: MessageOptions(
          showCurrentUserAvatar: widget.showCurrentUserAvatar,
          showOtherUsersAvatar: widget.showOtherUsersAvatar,
          showTime: widget.showMessageTime,
          showOtherUsersName: widget.showUserName,
          avatarBuilder: _customAvatarBuilder,
          messageDecorationBuilder: _messageDecorationBuilder,
          messageTextBuilder: _messageTextBuilder,
          currentUserContainerColor: widget.messageBackgroundColor ?? buttonColor,
          containerColor: widget.messageBackgroundColor?.withOpacity(0.1) ?? 
                         buttonColor.withOpacity(0.1),
          textColor: widget.textColor ?? Colors.black87,
          currentUserTextColor: widget.textColor ?? whiteAccent,
          messagePadding: widget.messagePadding ?? const EdgeInsets.all(12),
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        
        // Input Configuration
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: widget.inputHint,
            hintStyle: widget.inputTextStyle ?? headingText.copyWith(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.inputRadius ?? 24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: widget.secondaryColor?.withOpacity(0.1) ?? 
                      buttonColor.withOpacity(0.05),
            contentPadding: widget.inputPadding ?? 
                           const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          inputTextStyle: widget.inputTextStyle ?? headingText.copyWith(
            fontSize: 14,
          ),
          maxInputLength: widget.maxInputLength,
          autocorrect: widget.autocorrect,
          sendButtonBuilder: widget.showSendButton ? _sendButtonBuilder : null,
          leading: widget.showAttachmentButton ? [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: widget.primaryColor ?? buttonColor,
              ),
              onPressed: _onAttachmentPressed,
            ),
          ] : null,
          trailing: widget.showMicrophoneButton ? [
            IconButton(
              icon: Icon(
                Icons.mic,
                color: widget.primaryColor ?? buttonColor,
              ),
              onPressed: _onMicrophonePressed,
            ),
          ] : null,
        ),
        
        // Message List Configuration
        messageListOptions: widget.messageListOptions ?? MessageListOptions(
          scrollPhysics: const BouncingScrollPhysics(),
        ),
        
        // Quick Reply Configuration
        quickReplyOptions: widget.quickReplyOptions ?? QuickReplyOptions(
          quickReplyBuilder: _quickReplyBuilder,
          quickReplyStyle: BoxDecoration()
        ),
        
        
        // Scroll to bottom configuration
        scrollToBottomOptions: ScrollToBottomOptions(
          disabled: !widget.scrollToBottomOnSend,
        ),
      ),
    );
  }

  // Custom Builders
  Widget _customAvatarBuilder(ChatUser user, Function? onAvatarTap, Function? onAvatarLongPress) {
    return GestureDetector(
      onTap: onAvatarTap != null ? () => onAvatarTap(user) : null,
      onLongPress: onAvatarLongPress != null ? () => onAvatarLongPress(user) : null,
      child: Container(
        width: widget.avatarSize ?? 36,
        height: widget.avatarSize ?? 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.primaryColor ?? buttonColor,
          image: user.profileImage != null 
              ? DecorationImage(
                  image: NetworkImage(user.profileImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: user.profileImage == null
            ? Center(
                child: Text(
                  user.firstName?.substring(0, 1).toUpperCase() ?? 
                  user.id.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: widget.textColor ?? whiteAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: (widget.avatarSize ?? 36) * 0.4,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  BoxDecoration _messageDecorationBuilder(ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
    bool isUser = message.user.id == widget.currentUser.id;
    
    return BoxDecoration(
      color: isUser 
          ? (widget.messageBackgroundColor ?? buttonColor)
          : (widget.messageBackgroundColor?.withOpacity(0.1) ?? buttonColor.withOpacity(0.1)),
      borderRadius: BorderRadius.circular(widget.messageRadius ?? 16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _messageTextBuilder(ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
    bool isUser = message.user.id == widget.currentUser.id;
    
    return Text(
      message.text,
      style: widget.messageTextStyle ?? headingText.copyWith(
        fontSize: 14,
        color: isUser 
            ? (widget.textColor ?? whiteAccent)
            : (widget.textColor ?? Colors.black87),
        height: 1.4,
      ),
    );
  }

  Widget _timeTextBuilder(ChatMessage message, ChatMessage? previousMessage, ChatMessage? nextMessage) {
    return Text(
      "${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}",
      style: widget.timeTextStyle ?? headingText.copyWith(
        fontSize: 10,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _sendButtonBuilder(Function() onSend) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: CircleAvatar(
        backgroundColor: widget.primaryColor ?? buttonColor,
        radius: 20,
        child: IconButton(
          icon: Icon(
            Icons.send,
            color: widget.textColor ?? whiteAccent,
            size: 18,
          ),
          onPressed: onSend,
        ),
      ),
    );
  }

  Widget _quickReplyBuilder(QuickReply quickReply) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: ElevatedButton(
        onPressed: () {
          onSend(ChatMessage(
            text: quickReply.title,
            user: widget.currentUser,
            createdAt: DateTime.now(),
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.primaryColor ?? buttonColor,
          foregroundColor: widget.textColor ?? whiteAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.messageRadius ?? 16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          quickReply.title,
          style: headingText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _typingIndicatorBuilder(List<ChatUser> users) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.showOtherUsersAvatar && users.isNotEmpty)
            _customAvatarBuilder(users.first, null, null),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.messageBackgroundColor?.withOpacity(0.1) ?? 
                     buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(widget.messageRadius ?? 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${users.map((u) => u.firstName ?? u.id).join(', ')} ${users.length == 1 ? 'is' : 'are'} typing',
                  style: headingText.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(widget.primaryColor ?? buttonColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scrollToBottomBuilder(Function() scrollToBottom) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FloatingActionButton.small(
        onPressed: scrollToBottom,
        backgroundColor: widget.primaryColor ?? buttonColor,
        child: Icon(
          Icons.keyboard_arrow_down,
          color: widget.textColor ?? whiteAccent,
        ),
      ),
    );
  }

  void _onAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: widget.primaryColor ?? buttonColor),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle photo selection
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: widget.primaryColor ?? buttonColor),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                // Handle camera
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file, color: widget.primaryColor ?? buttonColor),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                // Handle document selection
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onMicrophonePressed() {
    // Handle voice recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording feature')),
    );
  }
}