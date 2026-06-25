import 'package:flutter/material.dart';

import '../../../core/services/revenuecat_service.dart';
import '../models/vault_package.dart';
import '../services/credit_service.dart';
import '../widgets/credit_summary_card.dart';
import '../widgets/purchase_package_card.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key, this.creditService});

  final CreditService? creditService;

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  late final CreditService _creditService =
      widget.creditService ?? CreditService();
  late Future<_CreditSummary> _summaryFuture;
  String? _busyPackage;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  Future<_CreditSummary> _loadSummary() async {
    final results = await Future.wait([
      _creditService.getCredits(),
      _creditService.hasAllVaults(),
      RevenueCatService.instance.getProductPriceMap(),
    ]);

    return _CreditSummary(
      credits: results[0] as int,
      hasAllVaults: results[1] as bool,
      packagePrices: results[2] as Map<String, String>,
    );
  }

  Future<void> _refreshSummary() async {
    setState(() {
      _summaryFuture = _loadSummary();
    });
  }

  Future<void> purchaseVaultPackage(VaultPackage package) async {
    if (_busyPackage != null) return;

    setState(() => _busyPackage = package.type.name);
    try {
      final purchaseResult = await RevenueCatService.instance
          .purchasePackageByProductIds(package.productIdentifiers);

      final purchasedProductId =
          purchaseResult.storeTransaction.productIdentifier;
      if (!package.productIdentifiers.contains(purchasedProductId)) {
        throw StateError('Satın alma ürünü doğrulanamadı.');
      }

      final credits = packageCreditMap[package.type];
      if (credits != null) {
        await _creditService.addCredits(credits);
      } else if (package.type == VaultPackageType.allVaults) {
        await _creditService.unlockAllVaults();
      }

      await _refreshSummary();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${package.title} satın alındı.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) setState(() => _busyPackage = null);
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    try {
      await RevenueCatService.instance.restorePurchases();
      await _refreshSummary();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alımlar başarıyla geri yüklendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  String _friendlyMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070D),
        foregroundColor: Colors.white,
        title: const Text('Satın Al'),
      ),
      body: FutureBuilder<_CreditSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _PurchaseErrorState(
              message: _friendlyMessage(snapshot.error!),
              onRetry: _refreshSummary,
            );
          }

          final summary =
              snapshot.data ??
              const _CreditSummary(credits: 0, hasAllVaults: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              CreditSummaryCard(
                credits: summary.credits,
                hasAllVaults: summary.hasAllVaults,
              ),
              const SizedBox(height: 18),
              for (final package in VaultPackage.values) ...[
                PurchasePackageCard(
                  title: package.title,
                  description: package.description,
                  buttonLabel: package.type == VaultPackageType.allVaults
                      ? 'Tüm Kasaları Aç'
                      : 'Satın Al',
                  isBusy: _busyPackage == package.type.name,
                  price: summary.packagePrices[package.productIdentifier],
                  onPressed: () => purchaseVaultPackage(package),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              _RestoreButton(
                isRestoring: _isRestoring,
                onRestore: _restorePurchases,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreditSummary {
  const _CreditSummary({
    required this.credits,
    required this.hasAllVaults,
    this.packagePrices = const {},
  });

  final int credits;
  final bool hasAllVaults;
  final Map<String, String> packagePrices;
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.isRestoring, required this.onRestore});

  final bool isRestoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: isRestoring ? null : onRestore,
        child: isRestoring
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Satın Alımları Geri Yükle',
                style: TextStyle(color: Color(0xFFA5A8B3)),
              ),
      ),
    );
  }
}

class _PurchaseErrorState extends StatelessWidget {
  const _PurchaseErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF6C85F),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
