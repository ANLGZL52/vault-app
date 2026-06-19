import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/purchase/screens/purchase_page.dart';
import '../features/referrals/services/referral_service.dart';
import '../features/referrals/widgets/puzzle_piece_card.dart';
import '../features/referrals/widgets/referral_code_card.dart';
import '../services/account_deletion_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
    super.key,
  });

  final User user;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<ReferralProfile?> _referralProfileFuture;
  late Future<bool> _emailVerifiedFuture;
  final ReferralService _referralService = ReferralService();
  final AccountDeletionService _accountDeletionService =
      AccountDeletionService();
  bool _isConvertingPuzzle = false;
  bool _isSendingVerificationEmail = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _referralProfileFuture = _loadReferralProfile();
    _emailVerifiedFuture = _loadEmailVerified();
  }

  Future<ReferralProfile?> _loadReferralProfile() async {
    try {
      return await _referralService.getReferralProfile();
    } catch (error, stackTrace) {
      debugPrint('Referral load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  String _friendlyMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.replaceFirst('Bad state: ', '');
  }

  Future<bool> _loadEmailVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      return FirebaseAuth.instance.currentUser?.emailVerified ??
          widget.user.emailVerified;
    } catch (error, stackTrace) {
      debugPrint('Email verification status load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return widget.user.emailVerified;
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSendingVerificationEmail) return;

    setState(() => _isSendingVerificationEmail = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
      }

      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama e-postası gönderildi.')),
      );
      setState(() {
        _emailVerifiedFuture = _loadEmailVerified();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) setState(() => _isSendingVerificationEmail = false);
    }
  }

  void _openPurchasePage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PurchasePage()));
  }

  Future<void> _copyReferralCode(String referralCode) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referans kodu kopyalandı')));
  }

  Future<void> _convertPuzzlePieces() async {
    if (_isConvertingPuzzle) return;

    setState(() => _isConvertingPuzzle = true);
    try {
      await _referralService.convertPuzzleToVaultCredit();
      if (!mounted) return;
      setState(() {
        _referralProfileFuture = _loadReferralProfile();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1 kasa hakkı eklendi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) setState(() => _isConvertingPuzzle = false);
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    if (_isDeletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111722),
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
          contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFFADB3C2),
            height: 1.4,
          ),
          title: const Text('Hesabını silmek istediğine emin misin?'),
          content: const Text(
            'Bu işlem geri alınamaz. Tüm hesap bilgilerin ve sana bağlı veriler silinebilir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);
    try {
      await _accountDeletionService.deleteCurrentUserAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = error.code == 'requires-recent-login'
          ? 'Güvenlik nedeniyle hesabını silmeden önce tekrar giriş yapmalısın.'
          : _friendlyMessage(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyMessage(error))));
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = widget.user.displayName?.trim();
    final email = widget.user.email ?? 'No email available';
    final displayName = name == null || name.isEmpty ? 'Vault User' : name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      children: [
        Text(
          'Profil',
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hesap bilgilerini ve oturumunu buradan yönet.',
          style: textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFADB3C2),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF151A24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(
                  0xFFFFC857,
                ).withValues(alpha: 0.14),
                child: Text(
                  displayName.characters.first.toUpperCase(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFFFC857),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFADB3C2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ProfileInfoTile(
          icon: Icons.person_outline_rounded,
          title: 'Name',
          value: displayName,
        ),
        const SizedBox(height: 12),
        _ProfileInfoTile(
          icon: Icons.mail_outline_rounded,
          title: 'Email',
          value: email,
        ),
        const SizedBox(height: 12),
        FutureBuilder<bool>(
          future: _emailVerifiedFuture,
          builder: (context, snapshot) {
            final isVerified = snapshot.data ?? widget.user.emailVerified;
            return _AccountStatusTile(
              isVerified: isVerified,
              isSending: _isSendingVerificationEmail,
              onVerifyEmail: _sendVerificationEmail,
            );
          },
        ),
        const SizedBox(height: 26),
        FutureBuilder<ReferralProfile?>(
          future: _referralProfileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileLoadingCard();
            }

            final profile = snapshot.data;
            if (profile == null) {
              return _ProfileInlineError(
                message: 'Referans kodu yüklenemedi',
                onRetry: () {
                  setState(() {
                    _referralProfileFuture = _loadReferralProfile();
                  });
                },
              );
            }

            return Column(
              children: [
                ReferralCodeCard(
                  referralCode: profile.referralCode,
                  onCopy: () => _copyReferralCode(profile.referralCode),
                ),
                const SizedBox(height: 12),
                PuzzlePieceCard(
                  puzzlePieces: profile.puzzlePieces,
                  isConverting: _isConvertingPuzzle,
                  onConvert: _convertPuzzlePieces,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _ProfileActionButton(
          icon: Icons.inventory_2_rounded,
          label: 'Kasa Paketi Satın Al',
          isBusy: false,
          onPressed: _openPurchasePage,
        ),
        const SizedBox(height: 26),
        FilledButton.icon(
          onPressed: widget.isLoggingOut ? null : widget.onLogout,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0x66FF6B6B),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: widget.isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(widget.isLoggingOut ? 'Logging out...' : 'Logout'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isDeletingAccount ? null : _confirmAndDeleteAccount,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF6B6B),
            side: const BorderSide(color: Color(0x55FF6B6B)),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: _isDeletingAccount
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF6B6B),
                  ),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: Text(_isDeletingAccount ? 'Siliniyor...' : 'Hesabı Sil'),
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: const Color(0xFFFFC857),
        side: const BorderSide(color: Color(0x33FFC857)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFFC857), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF8E95A3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _AccountStatusTile extends StatelessWidget {
  const _AccountStatusTile({
    required this.isVerified,
    required this.isSending,
    required this.onVerifyEmail,
  });

  final bool isVerified;
  final bool isSending;
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    final statusText = isVerified ? 'Email verified' : 'Email not verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC857).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_rounded
                  : Icons.verified_user_outlined,
              color: const Color(0xFFFFC857),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Status',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF8E95A3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isVerified) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSending ? null : onVerifyEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFC857),
                      side: const BorderSide(color: Color(0x33FFC857)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined, size: 18),
                    label: Text(isSending ? 'Sending...' : 'Verify Email'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileInlineError extends StatelessWidget {
  const _ProfileInlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFFC857)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            tooltip: 'Tekrar Dene',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
