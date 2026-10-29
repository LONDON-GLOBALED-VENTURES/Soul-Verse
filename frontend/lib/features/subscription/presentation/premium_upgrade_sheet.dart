import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/legal_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/presentation/widgets/sign_in_prompt_dialog.dart';
import '../application/premium_providers.dart';
import '../data/billing_service.dart';

/// The SoulVerse Premium paywall. Returns true if the user ends up with
/// Premium (subscribed or restored), so callers can carry on with what they
/// were trying to do.
Future<bool> showPremiumUpgradeSheet(BuildContext context) async {
  final unlocked = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _Paywall(),
  );
  return unlocked ?? false;
}

class _Paywall extends ConsumerStatefulWidget {
  const _Paywall();

  @override
  ConsumerState<_Paywall> createState() => _PaywallState();
}

class _PaywallState extends ConsumerState<_Paywall> {
  bool _busy = false;
  String? _message;

  String get _storeName => Platform.isIOS ? 'the App Store' : 'Google Play';

  /// Subscriptions belong to an account, so guests sign in first.
  Future<bool> _signedIn() async {
    if (ref.read(authProvider).value != null) return true;
    final signedIn = await showSignInPromptDialog(
      context,
      title: 'Sign in to subscribe',
      message:
          'Premium is linked to your account, so it stays with you if you '
          'change or reinstall your phone.',
      icon: Icons.auto_awesome,
    );
    if (!signedIn) return false;
    // Wait until the store account is linked to the user before buying.
    await ref.read(premiumEntitlementProvider.future);
    return mounted;
  }

  void _close({required String message}) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Sign-in happens before the spinner, which shouldn't spin behind the
  // account picker.
  Future<void> _subscribe() async {
    if (!await _signedIn()) return;
    await _run(_purchase);
  }

  Future<void> _purchase() async {
    if (ref.read(isPremiumProvider)) {
      _close(message: 'You already have SoulVerse Premium.');
      return;
    }
    try {
      final outcome = await ref.read(billingServiceProvider).purchasePremium();
      if (!mounted) return;
      switch (outcome) {
        case PurchaseOutcome.purchased:
          _close(message: 'Welcome to SoulVerse Premium!');
        case PurchaseOutcome.pending:
          setState(
            () => _message =
                'Your payment is being processed. Premium unlocks as soon '
                'as $_storeName confirms it.',
          );
        case PurchaseOutcome.cancelled:
          break;
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Couldn\'t complete the purchase. Please try again.',
        );
      }
    }
  }

  Future<void> _restore() async {
    if (!await _signedIn()) return;
    await _run(_restorePurchases);
  }

  Future<void> _restorePurchases() async {
    try {
      final restored = await ref.read(billingServiceProvider).restore();
      if (!mounted) return;
      if (restored) {
        _close(message: 'Your SoulVerse Premium is restored.');
      } else {
        setState(
          () => _message =
              'We couldn\'t find a Premium subscription for this '
              '$_storeName account.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Couldn\'t restore purchases. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final offer = ref.watch(premiumOfferProvider);
    final trialDays = offer.value?.trialDays;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFD4AF37),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SoulVerse Premium',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: AppFonts.serif,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make every verse your own.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const _FeatureRow(
              icon: Icons.add_photo_alternate_outlined,
              title: 'Your own photos',
              subtitle: 'Use any picture from your gallery as the background',
            ),
            const SizedBox(height: 14),
            const _FeatureRow(
              icon: Icons.brush_outlined,
              title: 'The full verse editor',
              subtitle:
                  'Fonts, colours, spacing, effects, highlights, notes '
                  'and placement',
            ),
            const SizedBox(height: 14),
            const _FeatureRow(
              icon: Icons.palette_outlined,
              title: 'Colours, gradients and filters',
              subtitle: 'Plain colours, gradients, blur and photo filters',
            ),
            const SizedBox(height: 24),
            _PriceCard(offer: offer),
            const SizedBox(height: 20),
            if (_message != null) ...[
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: _busy
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: offer.value == null ? null : _subscribe,
                      child: Text(
                        trialDays != null
                            ? 'Start $trialDays-day free trial'
                            : 'Subscribe',
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restore purchases'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Maybe later',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Required by the stores: what renews, when, and how to cancel.
            Text(
              '${trialDays != null ? 'After the $trialDays-day free trial, '
                        'your' : 'Your'} subscription is charged to your '
              '$_storeName account each month and renews automatically '
              'unless you cancel at least 24 hours before the end of the '
              'period. Cancel anytime in your $_storeName subscriptions.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (termsUrl.isNotEmpty || privacyUrl.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (termsUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => openExternalUrl(termsUrl),
                      child: const Text('Terms of Use'),
                    ),
                  if (privacyUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => openExternalUrl(privacyUrl),
                      child: const Text('Privacy Policy'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends ConsumerWidget {
  const _PriceCard({required this.offer});

  final AsyncValue<PremiumOffer?> offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final Widget content = switch (offer) {
      AsyncData(value: final offer?) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  offer.trialDays != null
                      ? '${offer.trialDays} days free, then billed monthly'
                      : 'Billed monthly, cancel anytime',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: offer.monthlyPrice,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                TextSpan(text: ' / month', style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
      AsyncLoading() => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      _ => Row(
        children: [
          Expanded(
            child: Text(
              'Premium isn\'t available right now. Please try again later.',
              style: textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(premiumOfferProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: content,
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
