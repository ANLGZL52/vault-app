import 'package:flutter/material.dart';

import '../models/vault_result.dart';

class VaultResultCard extends StatelessWidget {
  const VaultResultCard({required this.result, super.key});

  final VaultResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x26FFC857)),
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
                  color: const Color(0xFFFFC857).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.topic,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          VaultSection(
            icon: Icons.auto_awesome_rounded,
            title: result.insight.title,
            content: result.insight.intro,
            isHero: true,
          ),
          VaultSection(
            icon: Icons.person_outline_rounded,
            title: 'Bu sende nasıl görünüyor olabilir?',
            content: result.insight.howItAppears,
          ),
          VaultSection(
            icon: Icons.groups_outlined,
            title: 'İnsanlar bunu nasıl algılıyor olabilir?',
            content: result.insight.howPeopleSeeIt,
          ),
          VaultSection(
            icon: Icons.warning_amber_rounded,
            title: 'Dikkat etmen gereken nokta',
            content: result.insight.watchOut,
          ),
          VaultSection(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Küçük tavsiye',
            content: result.insight.advice,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(label: 'Model', value: result.model),
              _MetaPill(label: 'Kasa', value: '#${result.vaultId}'),
            ],
          ),
        ],
      ),
    );
  }
}

class VaultSection extends StatelessWidget {
  const VaultSection({
    required this.icon,
    required this.title,
    required this.content,
    this.isHero = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String content;
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty && title.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = isHero ? const Color(0xFFFFC857) : const Color(0xFFB8C7FF);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHero
            ? const Color(0xFFFFC857).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHero ? const Color(0x33FFC857) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (content.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFE4E8F2),
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFFB9BECA),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
