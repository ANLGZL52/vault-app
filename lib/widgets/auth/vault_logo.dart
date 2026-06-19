import 'package:flutter/material.dart';

class VaultLogo extends StatelessWidget {
  const VaultLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 70.0 : 86.0;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC857).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x44FFC857)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22FFC857),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_rounded,
            size: compact ? 34 : 42,
            color: const Color(0xFFFFC857),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'VAULT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFFFC857),
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}
