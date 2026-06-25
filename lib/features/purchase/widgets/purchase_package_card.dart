import 'package:flutter/material.dart';

class PurchasePackageCard extends StatelessWidget {
  const PurchasePackageCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    required this.isBusy,
    this.price,
    super.key,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isBusy;
  final String? price;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C85F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFF6C85F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFA5A8B3),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (price != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6C85F).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF6C85F).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    price!,
                    style: textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFF6C85F),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: isBusy ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF6C85F),
                  foregroundColor: const Color(0xFF05070D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF05070D),
                        ),
                      )
                    : Text(buttonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
