import 'package:flutter/material.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color primaryColor;
  final double size;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.primaryColor,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (currentPage + 1) / totalPages,
              strokeWidth: 3,
              backgroundColor: primaryColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          // Center text
          Center(
            child: Text(
              '${currentPage + 1}/$totalPages',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
