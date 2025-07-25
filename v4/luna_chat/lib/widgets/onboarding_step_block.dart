import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';

class OnboardingStepBlock extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  final List<String> images;
  final Color mainColor;
  final Color lightColor;

  const OnboardingStepBlock({
    super.key,
    required this.step,
    required this.title,
    required this.desc,
    required this.images,
    required this.mainColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 500,
      child: Container(
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250, // 500 * 1/2
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP $step',
                      style: mainText.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: headingText.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: mainText.copyWith(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 250, // 500 * 1/2
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(28),
                child:
                    images.length == 1
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(images[0], fit: BoxFit.contain),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              images
                                  .map(
                                    (img) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.asset(
                                            img,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
