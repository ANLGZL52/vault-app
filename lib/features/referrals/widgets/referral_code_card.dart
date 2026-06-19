import 'package:flutter/material.dart';

class ReferralCodeCard extends StatelessWidget {
  const ReferralCodeCard({
    required this.referralCode,
    required this.onCopy,
    super.key,
  });

  final String referralCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.ios_share_rounded,
              color: Color(0xFFFFC857),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referans Kodun',
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF8E95A3),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  referralCode,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Kopyala',
            icon: const Icon(Icons.copy_rounded, color: Color(0xFFFFC857)),
          ),
        ],
      ),
    );
  }
}
