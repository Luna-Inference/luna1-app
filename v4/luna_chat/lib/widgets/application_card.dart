import 'package:flutter/material.dart';
import 'package:luna_chat/data/application_list.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/theme.dart';
import 'package:luna_chat/widgets/snack_bar.dart';

class ApplicationCard extends StatelessWidget {
  final LunaApplication app;
  // final VoidCallback? onTap;
  
  const ApplicationCard({
    super.key,
    required this.app,
    // this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (app.widget != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => app.widget!));
        } else {
          context.showLunaSnackBar(
            message: 'This application is coming soon!',
            type: SnackBarType.info,
          );
        }
      },
      child: Container(
        decoration: LunaTheme.cardDecoration,
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
                  border: Border(bottom: BorderSide(color: cardBorder)),
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
                            style: cardSubtitle.copyWith(color: primaryText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (app.widget == null) ...[ 
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: app.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Soon',
                              style: badgeTextSmall.copyWith(color: app.color),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        app.description,
                        style: cardDescriptionSmall.copyWith(color: secondaryText),
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
      ),
    );
  }
}