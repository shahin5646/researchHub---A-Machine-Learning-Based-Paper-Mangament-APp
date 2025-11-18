import 'package:flutter/material.dart';

class ResearchHubLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool isDark;

  const ResearchHubLogo({
    super.key,
    this.fontSize = 40,
    this.showTagline = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              letterSpacing: -1.0,
            ),
            children: [
              TextSpan(
                text: 'Research',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              TextSpan(
                text: 'Hub',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Advancing knowledge through research',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }
}
