import 'package:flutter/material.dart';

class PuzzlePieceCard extends StatelessWidget {
  const PuzzlePieceCard({
    required this.puzzlePieces,
    required this.isConverting,
    required this.onConvert,
    super.key,
  });

  final int puzzlePieces;
  final bool isConverting;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPieces = puzzlePieces.clamp(0, 5);
    final canConvert = puzzlePieces >= 5;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC857).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  color: Color(0xFFFFC857),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Puzzle Parçaları: $puzzlePieces / 5',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progressPieces / 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: const Color(0xFFFFC857),
            ),
          ),
          if (canConvert) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isConverting ? null : onConvert,
                icon: isConverting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF050810),
                        ),
                      )
                    : const Icon(Icons.inventory_2_rounded),
                label: const Text('5 Parçayı 1 Kasa Hakkına Çevir'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
