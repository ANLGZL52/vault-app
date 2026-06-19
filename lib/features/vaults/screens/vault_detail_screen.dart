import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/premium_guard.dart';
import '../data/vault_topics.dart';
import '../models/vault_result.dart';
import '../services/vault_service.dart';
import '../widgets/vault_result_card.dart';

class VaultDetailScreen extends StatefulWidget {
  const VaultDetailScreen({required this.vaultId, super.key, this.service});

  final int vaultId;
  final VaultService? service;

  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen> {
  late final VaultService _service = widget.service ?? VaultService();
  late Future<VaultResult?> _openedVaultFuture;
  late Future<bool> _canOpenVaultFuture;
  VaultResult? _result;
  bool _isOpening = false;

  String get _topic => vaultTopics[widget.vaultId] ?? 'Kasa bulunamadı';
  bool get _isFree => isVaultFree(widget.vaultId);

  @override
  void initState() {
    super.initState();
    _openedVaultFuture = _service.getOpenedVault(widget.vaultId);
    _canOpenVaultFuture = _service.canOpenVault(widget.vaultId);
  }

  Future<void> _openVault() async {
    if (_isOpening) return;

    _debugLog('STEP 1: Vault open button pressed');
    _debugLog('vault id: ${widget.vaultId}');
    _debugLog('is free vault: $_isFree');

    setState(() => _isOpening = true);
    try {
      if (!_isFree) {
        if (!mounted) return;
        final canOpen = await PremiumGuard.instance.canOpenVault(
          context: context,
          vaultId: widget.vaultId,
        );
        if (!canOpen) return;
      }

      _debugLog('STEP 2: Subscription/package validation passed');

      final result = await _service.openVault(widget.vaultId);
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kasa başarıyla açıldı.')));
    } catch (error, stackTrace) {
      _debugLog('Vault open flow failed: $error');
      _debugStack(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    final normalized = message.toLowerCase();
    if (normalized.contains('ai sonucu') ||
        normalized.contains('analiz oluşturulamadı') ||
        normalized.contains('api hatası') ||
        normalized.contains('api anahtarı') ||
        normalized.contains('firebase cloud functions') ||
        normalized.contains('missing authentication header') ||
        normalized.contains('401')) {
      return 'AI sonucu alınamadı. Lütfen biraz sonra tekrar dene.';
    }

    if (message.trim().isEmpty) {
      return 'Kasa açılırken bir sorun oluştu.';
    }

    return message;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[VaultAI] $message');
    }
  }

  void _debugStack(StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050810),
        foregroundColor: Colors.white,
        title: Text('Kasa ${widget.vaultId}'),
      ),
      body: FutureBuilder<VaultResult?>(
        future: _openedVaultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loadedResult = _result ?? snapshot.data;
          if (loadedResult != null) {
            return _VaultDetailContent(result: loadedResult);
          }

          if (snapshot.hasError) {
            return _VaultErrorState(
              message: _errorMessage(snapshot.error!),
              onRetry: () {
                setState(() {
                  _openedVaultFuture = _service.getOpenedVault(widget.vaultId);
                  _canOpenVaultFuture = _service.canOpenVault(widget.vaultId);
                });
              },
            );
          }

          return FutureBuilder<bool>(
            future: _canOpenVaultFuture,
            builder: (context, accessSnapshot) {
              return _LockedOrUnopenedState(
                vaultId: widget.vaultId,
                topic: _topic,
                isFree: _isFree,
                canOpenWithAllowance: accessSnapshot.data == true,
                isCheckingAccess:
                    accessSnapshot.connectionState == ConnectionState.waiting,
                isOpening: _isOpening,
                onOpen: _openVault,
              );
            },
          );
        },
      ),
    );
  }
}

class _VaultDetailContent extends StatelessWidget {
  const _VaultDetailContent({required this.result});

  final VaultResult result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [VaultResultCard(result: result)],
    );
  }
}

class _LockedOrUnopenedState extends StatelessWidget {
  const _LockedOrUnopenedState({
    required this.vaultId,
    required this.topic,
    required this.isFree,
    required this.canOpenWithAllowance,
    required this.isCheckingAccess,
    required this.isOpening,
    required this.onOpen,
  });

  final int vaultId;
  final String topic;
  final bool isFree;
  final bool canOpenWithAllowance;
  final bool isCheckingAccess;
  final bool isOpening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF111722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isFree
                          ? Icons.inventory_2_rounded
                          : Icons.workspace_premium_rounded,
                      color: const Color(0xFFFFC857),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      isFree ? 'Ücretsiz Kasa' : 'Paketli Kasa',
                      style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFFFC857),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '#$vaultId',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                topic,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFree
                    ? 'Bu kasa kişilik testi sonucuna göre tek seferlik kişisel bir analiz üretir. Açıldıktan sonra tekrar API çağrısı yapılmadan kayıtlı sonuç gösterilir.'
                    : 'Bu kasa paket hakkı kullanarak açılır. Açıldıktan sonra tekrar API çağrısı yapılmadan kayıtlı sonuç gösterilir.',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB7BDCB),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isOpening || isCheckingAccess ? null : onOpen,
                  icon: isOpening || isCheckingAccess
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF050810),
                          ),
                        )
                      : Icon(
                          isFree
                              ? Icons.lock_open_rounded
                              : Icons.workspace_premium_rounded,
                        ),
                  label: Text(_buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _buttonLabel {
    if (isOpening) return 'Açılıyor...';
    if (isCheckingAccess) return 'Kontrol ediliyor...';
    if (isFree) return 'Kasayı Aç';
    if (canOpenWithAllowance) return 'Paketle Aç';
    return 'Paketi Satın Al';
  }
}

class _VaultErrorState extends StatelessWidget {
  const _VaultErrorState({required this.message, required this.onRetry});

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
              color: Color(0xFFFFC857),
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFDDE2EE)),
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
