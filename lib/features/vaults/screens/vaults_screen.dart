import 'package:flutter/material.dart';

import '../../purchase/services/credit_service.dart';
import '../data/vault_topics.dart';
import '../services/vault_service.dart';
import 'vault_detail_screen.dart';

const _bg = Color(0xFF05070D);
const _card = Color(0xFF101720);
const _gold = Color(0xFFF6C85F);
const _textSecondary = Color(0xFFA5A8B3);
const _lockedText = Color(0xFF8E95A3);

const _displayTitleOverrides = <int, String>{
  1: 'İnsanların sende fark ettiği ama senin fark etmediğin şey',
  2: 'İnsanların sana karşı ilk önyargısı',
  3: 'Seni ilk tanıyanların aklında kalan şey',
  4: 'En büyük kör noktan',
  5: 'Seni zorlayan ama geliştiren şey',
  6: 'Gizli gücün',
};

class VaultsScreen extends StatefulWidget {
  const VaultsScreen({super.key});

  @override
  State<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends State<VaultsScreen> {
  late Future<_VaultsAccessSnapshot> _accessSnapshotFuture;

  @override
  void initState() {
    super.initState();
    _accessSnapshotFuture = _loadAccessSnapshot();
  }

  Future<_VaultsAccessSnapshot> _loadAccessSnapshot() async {
    try {
      final results = await Future.wait([
        VaultService().getOpenedVaultIds(),
        CreditService().getCredits(),
        CreditService().hasAllVaults(),
      ]);

      return _VaultsAccessSnapshot(
        openedVaultIds: results[0] as Set<int>,
        vaultCredits: results[1] as int,
        hasAllVaults: results[2] as bool,
      );
    } catch (error, stackTrace) {
      debugPrint('Vaults access snapshot failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const _VaultsAccessSnapshot.empty();
    }
  }

  void _openVault(BuildContext context, int vaultId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => VaultDetailScreen(vaultId: vaultId),
          ),
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            _accessSnapshotFuture = _loadAccessSnapshot();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VaultsAccessSnapshot>(
      future: _accessSnapshotFuture,
      builder: (context, snapshot) {
        final access = snapshot.data ?? const _VaultsAccessSnapshot.empty();

        return Stack(
          children: [
            const _VaultsBackground(),
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _VaultsHeader(),
                        const SizedBox(height: 30),
                        Text(
                          'Kasalar',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _VaultsDescription(
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _textSecondary,
                                height: 1.36,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 34),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = MediaQuery.of(context).size.width < 380;
                        final spacing = constraints.maxWidth < 380
                            ? 14.0
                            : 18.0;
                        final itemWidth = (constraints.maxWidth - spacing) / 2;
                        final cardHeight = isSmall ? 292.0 : 305.0;
                        final titleFontSize = isSmall ? 14.5 : 16.0;
                        final chestHeight = isSmall ? 82.0 : 92.0;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final entry in vaultTopics.entries)
                              Builder(
                                builder: (context) {
                                  final isOpened = access.openedVaultIds
                                      .contains(entry.key);
                                  final isLocked = isVaultLocked(
                                    vaultId: entry.key,
                                    isOpened: isOpened,
                                    vaultCredits: access.vaultCredits,
                                    hasAllVaults: access.hasAllVaults,
                                  );
                                  final statusLabel = getVaultStatusLabel(
                                    vaultId: entry.key,
                                    isOpened: isOpened,
                                    vaultCredits: access.vaultCredits,
                                    hasAllVaults: access.hasAllVaults,
                                  );

                                  return SizedBox(
                                    width: itemWidth,
                                    height: cardHeight,
                                    child: _VaultCard(
                                      vaultId: entry.key,
                                      title:
                                          _displayTitleOverrides[entry.key] ??
                                          entry.value,
                                      isLocked: isLocked,
                                      isOpened: isOpened,
                                      statusLabel: statusLabel,
                                      titleFontSize: titleFontSize,
                                      chestHeight: chestHeight,
                                      onTap: () =>
                                          _openVault(context, entry.key),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _VaultsAccessSnapshot {
  const _VaultsAccessSnapshot({
    required this.openedVaultIds,
    required this.vaultCredits,
    required this.hasAllVaults,
  });

  const _VaultsAccessSnapshot.empty()
    : openedVaultIds = const {},
      vaultCredits = 0,
      hasAllVaults = false;

  final Set<int> openedVaultIds;
  final int vaultCredits;
  final bool hasAllVaults;
}

String getVaultStatusLabel({
  required int vaultId,
  required bool isOpened,
  required int vaultCredits,
  required bool hasAllVaults,
}) {
  if (isOpened) return 'Açıldı';
  if (vaultId <= freeVaultLimit) return 'Açılabilir';
  if (hasAllVaults) return 'Açılabilir';
  if (vaultCredits > 0) return 'Açılabilir';
  return 'Kilitli';
}

bool isVaultLocked({
  required int vaultId,
  required bool isOpened,
  required int vaultCredits,
  required bool hasAllVaults,
}) {
  if (isOpened) return false;
  if (vaultId <= freeVaultLimit) return false;
  if (hasAllVaults) return false;
  if (vaultCredits > 0) return false;
  return true;
}

class _VaultsBackground extends StatelessWidget {
  const _VaultsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.15,
          colors: [Color(0xFF111B26), _bg],
          stops: [0, 0.72],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.03),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.18),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultsHeader extends StatelessWidget {
  const _VaultsHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'VAULT',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: _gold,
          fontWeight: FontWeight.w900,
          letterSpacing: 9,
        ),
      ),
    );
  }
}

class _VaultsDescription extends StatelessWidget {
  const _VaultsDescription({this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: style,
        children: const [
          TextSpan(text: 'İlk 3 kasa ücretsiz. Diğer kasalar\n'),
          TextSpan(text: 'yakında '),
          TextSpan(
            text: 'paketlerle',
            style: TextStyle(color: _gold),
          ),
          TextSpan(text: ' açılacak.'),
        ],
      ),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    required this.vaultId,
    required this.title,
    required this.isLocked,
    required this.isOpened,
    required this.statusLabel,
    required this.titleFontSize,
    required this.chestHeight,
    required this.onTap,
  });

  final int vaultId;
  final String title;
  final bool isLocked;
  final bool isOpened;
  final String statusLabel;
  final double titleFontSize;
  final double chestHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnlockedVisual = !isLocked;
    final borderColor = isUnlockedVisual
        ? _gold.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.12);
    final mainTextColor = isUnlockedVisual ? Colors.white : _lockedText;
    final accent = isOpened
        ? const Color(0xFF65D58B)
        : isUnlockedVisual
        ? _gold
        : _lockedText;
    final asset = isUnlockedVisual
        ? 'images/yesilkasa.png'
        : 'images/kilitlikasa.png';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              if (isUnlockedVisual)
                BoxShadow(
                  color: _gold.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlockedVisual
                  ? [
                      const Color(0xFF111B24),
                      const Color(0xFF081018),
                      _gold.withValues(alpha: 0.05),
                    ]
                  : [
                      const Color(0xFF111821),
                      const Color(0xFF070D14),
                      Colors.white.withValues(alpha: 0.015),
                    ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.92,
                      colors: [
                        (isUnlockedVisual ? _gold : Colors.white).withValues(
                          alpha: isUnlockedVisual ? 0.11 : 0.035,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _VaultNumberBadge(
                            vaultId: vaultId,
                            isUnlockedVisual: isUnlockedVisual,
                          ),
                          Icon(
                            isOpened
                                ? Icons.check_circle_rounded
                                : isUnlockedVisual
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: accent,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: chestHeight,
                      child: Center(
                        child: _ChestImage(
                          asset: asset,
                          height: chestHeight,
                          isUnlockedVisual: isUnlockedVisual,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 62,
                      child: Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: mainTextColor,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                letterSpacing: 0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: _VaultStatusPill(
                        isUnlockedVisual: isUnlockedVisual,
                        isOpened: isOpened,
                        label: statusLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChestImage extends StatelessWidget {
  const _ChestImage({
    required this.asset,
    required this.height,
    required this.isUnlockedVisual,
  });

  final String asset;
  final double height;
  final bool isUnlockedVisual;

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: height * 1.42,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!isUnlockedVisual) {
      return Opacity(opacity: 0.72, child: image);
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        _gold.withValues(alpha: 0.5),
        BlendMode.modulate,
      ),
      child: image,
    );
  }
}

class _VaultNumberBadge extends StatelessWidget {
  const _VaultNumberBadge({
    required this.vaultId,
    required this.isUnlockedVisual,
  });

  final int vaultId;
  final bool isUnlockedVisual;

  @override
  Widget build(BuildContext context) {
    final color = isUnlockedVisual ? _gold : _lockedText;

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isUnlockedVisual ? _gold : Colors.white).withValues(
          alpha: isUnlockedVisual ? 0.12 : 0.06,
        ),
      ),
      child: Text(
        '$vaultId',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _VaultStatusPill extends StatelessWidget {
  const _VaultStatusPill({
    required this.isUnlockedVisual,
    required this.isOpened,
    required this.label,
  });

  final bool isUnlockedVisual;
  final bool isOpened;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isOpened
        ? const Color(0xFF65D58B)
        : isUnlockedVisual
        ? _gold
        : _lockedText;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      width: double.infinity,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: isUnlockedVisual ? 0.055 : 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
