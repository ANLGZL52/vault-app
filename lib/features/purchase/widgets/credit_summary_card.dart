import 'package:flutter/material.dart';

class CreditSummaryCard extends StatelessWidget {
  const CreditSummaryCard({
    required this.credits,
    required this.hasAllVaults,
    super.key,
  });

  final int credits;
  final bool hasAllVaults;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remainingText = hasAllVaults ? 'Tüm kasalar açık' : '$credits';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C85F).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFFF6C85F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Kasa Kredilerin',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Kalan Kasa Hakkı: $remainingText',
            style: textTheme.headlineSmall?.copyWith(
              color: const Color(0xFFF6C85F),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk 3 kasa ücretsizdir. Kilitli kasalar kredi kullanarak açılır.',
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFA5A8B3),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
