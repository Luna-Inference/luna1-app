import 'package:flutter/material.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';

class SimpleChatBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final bool isUserMessage;
  final bool showTail;
  final Widget? leading;
  final Widget? trailing;
  
  const SimpleChatBubble({
    super.key,
    required this.text,
    this.maxWidth = 300,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.padding,
    this.isUserMessage = false,
    this.showTail = true,
    this.leading,
    this.trailing,
  });
  
  @override
  Widget build(BuildContext context) {
    final bubbleColor = backgroundColor ?? 
        (isUserMessage ? chatBlue : Colors.grey.shade200);
    final messageBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(isUserMessage ? 20 : 4),
      topRight: Radius.circular(isUserMessage ? 4 : 20),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (leading != null && !isUserMessage) leading!,
        if (showTail && !isUserMessage)
          CustomPaint(
            painter: SimpleChatBubbleTail(
              color: bubbleColor,
              isUserMessage: false,
            ),
            size: const Size(8, 15),
          ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: messageBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              style: textStyle ?? mainText.copyWith(
                fontSize: 16,
                color: textColor ?? (isUserMessage ? Colors.white : Colors.black87),
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ),
        if (showTail && isUserMessage)
          CustomPaint(
            painter: SimpleChatBubbleTail(
              color: bubbleColor,
              isUserMessage: true,
            ),
            size: const Size(8, 15),
          ),
        if (trailing != null && isUserMessage) trailing!,
      ],
    );
  }
}

class SimpleChatBubbleTail extends CustomPainter {
  final Color color;
  final bool isUserMessage;
  
  SimpleChatBubbleTail({required this.color, required this.isUserMessage});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    if (isUserMessage) {
      // Right side tail (for user messages)
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height / 2);
      path.close();
    } else {
      // Left side tail (for received messages)
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height / 2);
      path.close();
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}