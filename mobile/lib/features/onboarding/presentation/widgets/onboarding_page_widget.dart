import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingPageWidget({super.key, required this.title, required this.description, required this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              textStyle: theme.textTheme.headlineSmall,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Illustration
          Flexible(
            child: Center(
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                height: 390,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 12, right: 12),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.bodyMedium,
                fontSize: 14,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
