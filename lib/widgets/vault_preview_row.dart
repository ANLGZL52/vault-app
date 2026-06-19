import 'package:flutter/material.dart';

import '../features/vaults/data/vault_topics.dart';
import '../features/vaults/screens/vault_detail_screen.dart';

class VaultPreviewRow extends StatelessWidget {
  const VaultPreviewRow({super.key});

  void _openVault(BuildContext context, int vaultId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VaultDetailScreen(vaultId: vaultId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _VaultCard(
            title: vaultTopics[1] ?? '',
            color: Color(0xFF6EE76B),
            index: 1,
            onTap: () => _openVault(context, 1),
          ),
          _VaultCard(
            title: vaultTopics[2] ?? '',
            color: Color(0xFF64B5F6),
            index: 2,
            onTap: () => _openVault(context, 2),
          ),
          _VaultCard(
            title: vaultTopics[3] ?? '',
            color: Color(0xFFB366FF),
            index: 3,
            onTap: () => _openVault(context, 3),
          ),
        ],
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    required this.title,
    required this.color,
    required this.index,
    required this.onTap,
  });

  final String title;
  final Color color;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Material(
        color: const Color(0xFF151A24),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: color.withValues(alpha: 0.16),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.inventory_2_rounded, color: color, size: 32),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.lock_open_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'ÜCRETSİZ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
