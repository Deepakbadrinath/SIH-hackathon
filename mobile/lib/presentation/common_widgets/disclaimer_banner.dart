import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7), // Gentle amber
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD97706),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF92400E),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.translate('app.disclaimer.banner'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
