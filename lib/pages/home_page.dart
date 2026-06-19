import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/purchase/services/credit_service.dart';
import '../features/referrals/services/referral_service.dart';
import '../features/vaults/data/vault_topics.dart';
import '../features/vaults/screens/vault_detail_screen.dart';
import '../features/vaults/services/vault_service.dart';

const _bg = Color(0xFF05070D);
const _card = Color(0xFF111821);
const _gold = Color(0xFFF6C85F);
const _textSecondary = Color(0xFFA5A8B3);
const _green = Color(0xFF65D58B);
const _blue = Color(0xFF66B5FF);
const _purple = Color(0xFFB58CFF);

class HomePage extends StatelessWidget {
  const HomePage({required this.user, required this.onOpenVaults, super.key});

  final User user;
  final VoidCallback onOpenVaults;

  Future<HomeDashboardData> _loadDashboardData() async {
    final openedVaultCount = await _safeReadInt(
      VaultService().getOpenedVaultCount,
    );
    final vaultCredits = await _safeReadInt(CreditService().getCredits);
    final puzzlePieces = await _safeReadInt(ReferralService().getPuzzlePieces);
    final friendCount = await _safeReadInt(() async {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referredBy', isEqualTo: user.uid)
          .get();
      return snapshot.docs.length;
    });

    return HomeDashboardData(
      openedVaultCount: openedVaultCount,
      vaultCredits: vaultCredits,
      puzzlePieces: puzzlePieces,
      friendCount: friendCount,
    );
  }

  Future<int> _safeReadInt(Future<int> Function() read) async {
    try {
      return await read();
    } catch (error, stackTrace) {
      debugPrint('Home dashboard read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeDashboardData>(
      future: _loadDashboardData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? HomeDashboardData.empty;

        return Stack(
          children: [
            const _HomeBackground(),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 124),
              children: [
                const HomeHeader(),
                const SizedBox(height: 30),
                HomeHero(displayName: _displayName),
                const SizedBox(height: 26),
                OpenedVaultProgressCard(
                  openedVaultCount: data.openedVaultCount,
                  onTap: onOpenVaults,
                ),
                const SizedBox(height: 22),
                HomeStatsRow(data: data),
                const SizedBox(height: 34),
                FreeVaultsSection(onOpenVaults: onOpenVaults),
              ],
            ),
          ],
        );
      },
    );
  }

  String get _displayName {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.split(RegExp(r'\s+')).first;
    }

    final emailName = user.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) {
      return emailName[0].toUpperCase();
    }

    return 'D';
  }
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.openedVaultCount,
    required this.vaultCredits,
    required this.puzzlePieces,
    required this.friendCount,
  });

  static const empty = HomeDashboardData(
    openedVaultCount: 0,
    vaultCredits: 0,
    puzzlePieces: 0,
    friendCount: 0,
  );

  final int openedVaultCount;
  final int vaultCredits;
  final int puzzlePieces;
  final int friendCount;
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _bg),
        child: Stack(
          children: [
            Positioned(
              top: -96,
              right: -72,
              child: _Glow(size: 260, color: _gold, opacity: 0.18),
            ),
            Positioned(
              top: 230,
              left: -150,
              child: _Glow(size: 260, color: _blue, opacity: 0.08),
            ),
            Positioned(
              bottom: 120,
              right: -170,
              child: _Glow(size: 320, color: _purple, opacity: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: const Icon(Icons.lock_rounded, color: _gold, size: 24),
        ),
        const SizedBox(width: 14),
        Text(
          'VAULT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 7,
          ),
        ),
      ],
    );
  }
}

class HomeHero extends StatelessWidget {
  const HomeHero({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 380;

    return SizedBox(
      height: isSmall ? 250 : 270,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: isSmall ? -58 : -48,
            top: isSmall ? 20 : 4,
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(
                'images/yesilkasa.png',
                width: isSmall ? 190 : 225,
                height: isSmall ? 190 : 225,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 8,
            right: isSmall ? 92 : 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $displayName.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                    fontSize: isSmall ? 39 : 46,
                  ),
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      fontSize: isSmall ? 25 : 29,
                    ),
                    children: const [
                      TextSpan(text: 'Kasaları aç,\n'),
                      TextSpan(
                        text: 'içgörüleri keşfet.',
                        style: TextStyle(color: _gold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Kişilik analizine özel hazırlanmış\niçgörülerin seni bekliyor.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _textSecondary,
                    height: 1.45,
                    fontSize: isSmall ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OpenedVaultProgressCard extends StatelessWidget {
  const OpenedVaultProgressCard({
    required this.openedVaultCount,
    required this.onTap,
    super.key,
  });

  final int openedVaultCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (openedVaultCount / vaultTopics.length).clamp(0.0, 1.0);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _gold.withValues(alpha: 0.34)),
                ),
                child: const Icon(Icons.lock_open_rounded, color: _gold),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Açılan Kasa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                        children: [
                          TextSpan(
                            text: '$openedVaultCount',
                            style: const TextStyle(color: _gold),
                          ),
                          TextSpan(text: ' / ${vaultTopics.length}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({required this.data, super.key});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 380 ? 155.0 : 168.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          HomeStatCard(
            width: cardWidth,
            icon: Icons.extension_rounded,
            title: 'Puzzle Parçası',
            value: '${data.puzzlePieces}',
            subtitle: '5 parça = 1 kasa',
            progress: (data.puzzlePieces % 5) / 5,
          ),
          const SizedBox(width: 14),
          HomeStatCard(
            width: cardWidth,
            icon: Icons.inventory_2_rounded,
            title: 'Kasa Kredisi',
            value: '${data.vaultCredits}',
            subtitle: 'Kasa açmak için kullanabilirsin.',
          ),
          const SizedBox(width: 14),
          HomeStatCard(
            width: cardWidth,
            icon: Icons.groups_2_rounded,
            title: 'Arkadaşın',
            value: '${data.friendCount}',
            subtitle: 'Referans kodunla katılan arkadaşın.',
          ),
        ],
      ),
    );
  }
}

class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.progress,
    super.key,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 172,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _gold, size: 28),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _gold,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _textSecondary,
                height: 1.2,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: progress!.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FreeVaultsSection extends StatelessWidget {
  const FreeVaultsSection({required this.onOpenVaults, super.key});

  final VoidCallback onOpenVaults;

  @override
  Widget build(BuildContext context) {
    final freeVaultIds = vaultTopics.keys.where(isVaultFree).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ücretsiz Kasaların',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenVaults,
              style: TextButton.styleFrom(
                foregroundColor: _gold,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('Tümünü Gör >'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (var index = 0; index < freeVaultIds.length; index++) ...[
                HomeVaultCard(
                  vaultId: freeVaultIds[index],
                  accent: _vaultAccent(index),
                  chestAsset: _vaultAsset(index),
                ),
                if (index != freeVaultIds.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _vaultAccent(int index) {
    return switch (index) {
      0 => _green,
      1 => _blue,
      _ => _gold,
    };
  }

  String _vaultAsset(int index) {
    return switch (index) {
      0 => 'images/yesilkasa.png',
      1 => 'images/mavikasa.png',
      _ => 'images/morkasa.png',
    };
  }
}

class HomeVaultCard extends StatelessWidget {
  const HomeVaultCard({
    required this.vaultId,
    required this.accent,
    required this.chestAsset,
    super.key,
  });

  final int vaultId;
  final Color accent;
  final String chestAsset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 380 ? 248.0 : 266.0;
    final cardHeight = width < 380 ? 376.0 : 382.0;
    final title = vaultTopics[vaultId] ?? 'Kasa';

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GlassCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VaultDetailScreen(vaultId: vaultId),
            ),
          );
        },
        borderColor: accent.withValues(alpha: 0.34),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -50,
              child: _Glow(size: 150, color: accent, opacity: 0.20),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                const topHeight = 48.0;
                const topGap = 14.0;
                const imageTitleGap = 12.0;
                const pillGap = 14.0;
                const pillHeight = 44.0;
                final titleHeight = width < 380 ? 78.0 : 84.0;
                final imageHeight =
                    (constraints.maxHeight -
                            topHeight -
                            topGap -
                            imageTitleGap -
                            titleHeight -
                            pillGap -
                            pillHeight)
                        .clamp(96.0, 128.0)
                        .toDouble();

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: topHeight,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.42),
                              ),
                            ),
                            child: Text(
                              '$vaultId',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.lock_open_rounded,
                            color: accent,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: topGap),
                    SizedBox(
                      height: imageHeight,
                      child: Image.asset(chestAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: imageTitleGap),
                    SizedBox(
                      height: titleHeight,
                      child: Center(
                        child: Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                fontSize: width < 380 ? 18 : 19,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: pillGap),
                    SizedBox(
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ücretsiz',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.075),
              Colors.white.withValues(alpha: 0.025),
              Colors.black.withValues(alpha: 0.04),
            ],
          ),
        ),
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: content,
      ),
    );
  }
}
