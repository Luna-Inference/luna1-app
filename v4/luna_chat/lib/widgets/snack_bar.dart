import 'package:flutter/material.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';

enum SnackBarType { success, error, info }

class LunaSnackBar extends StatelessWidget {
  final String message;
  final SnackBarType type;

  const LunaSnackBar({
    super.key,
    required this.message,
    this.type = SnackBarType.info,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case SnackBarType.success:
        return successColor;
      case SnackBarType.error:
        return errorColor;
      case SnackBarType.info:
      default:
        return infoColor;
    }
  }

  IconData _getIconData() {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getIconData(),
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: bodyText.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

extension ShowLunaSnackBar on BuildContext {
  void showLunaSnackBar({
    required String message,
    SnackBarType type = SnackBarType.info,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: LunaSnackBar(
          message: message,
          type: type,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}