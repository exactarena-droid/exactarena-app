import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../models/plan.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    // Pay-on-web: subscriptions are purchased on the website, never via IAP.
    final config = ref.watch(appConfigProvider).valueOrNull;
    final subscribeUrl = config?.subscribeUrl;
    final isPremium = ref.watch(authControllerProvider).user?.isPremium ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium plans')),
      body: AsyncView(
        value: plans,
        loading: const ListSkeleton(count: 3),
        onRetry: () => ref.invalidate(plansProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: LucideIcons.crown,
              title: 'No plans available',
              message: 'Premium plans will appear here when available.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _CurrentPlanBanner(isPremium: isPremium),
              for (final p in list)
                _PlanCard(
                  plan: p,
                  isPremium: isPremium,
                  subscribeUrl: subscribeUrl,
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: _ManageSubscriptionNote(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final bool isPremium;
  const _CurrentPlanBanner({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPremium ? t.brandSubtle : t.surfaceMuted,
        borderRadius: BorderRadius.circular(TerraceRadii.lg),
        border: Border.all(color: isPremium ? t.brand : t.border),
      ),
      child: Row(
        children: [
          Icon(isPremium ? LucideIcons.crown : LucideIcons.user, size: 18, color: isPremium ? t.brand : t.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPremium
                  ? "You're on Premium — manage your subscription on the web."
                  : "You're on the Free plan. Subscribe on the web to go Premium.",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: isPremium ? t.brand : t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageSubscriptionNote extends StatelessWidget {
  const _ManageSubscriptionNote();

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Row(
      children: [
        Icon(LucideIcons.globe, size: 15, color: t.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Payments happen on the web — never inside the app.',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isPremium;
  final String? subscribeUrl;
  const _PlanCard({
    required this.plan,
    required this.isPremium,
    required this.subscribeUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final featured = plan.isFeatured;
    final priceText = plan.isFree
        ? 'Free'
        : NumberFormat.simpleCurrency(name: plan.currency).format(plan.price);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        border: Border.all(
          color: featured ? t.accent : t.border,
          width: featured ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              width: double.infinity,
              color: t.accent.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 14, color: t.accent),
                    const SizedBox(width: 6),
                    Text('MOST POPULAR',
                        style: TextStyle(color: t.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.headlineSmall),
                if (plan.description != null) ...[
                  const SizedBox(height: 4),
                  Text(plan.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(priceText, style: TerraceTextStyles.scoreboard(context, size: 32)),
                    if (!plan.isFree && plan.interval != null) ...[
                      const SizedBox(width: 6),
                      Text('/ ${plan.interval}', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                for (final f in plan.features)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.check, size: 18, color: t.brand),
                        const SizedBox(width: 10),
                        Expanded(child: Text(f, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _isCurrent
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: const Text('Current plan'),
                        )
                      : plan.isFree
                          ? const OutlinedButton(onPressed: null, child: Text('Included'))
                          : FilledButton.icon(
                              onPressed: () => _onUpgrade(context),
                              style: featured
                                  ? FilledButton.styleFrom(backgroundColor: t.accent, foregroundColor: Colors.white)
                                  : null,
                              icon: const Icon(LucideIcons.externalLink, size: 16),
                              label: const Text('Subscribe on the web'),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The fan's current plan: Free when not premium, the premium tiers when premium.
  bool get _isCurrent => plan.isFree ? !isPremium : isPremium;

  /// Pay-on-web: no in-app purchase. Opens the website subscribe page in an external browser so the fan
  /// completes checkout there (App-Store-safe and COMPLIANCE-safe — premium content access only).
  Future<void> _onUpgrade(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = subscribeUrl;
    if (url == null || url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Subscribe from the Terrace website to go Premium.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    final launched = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open the subscribe page. Please try again.")),
      );
    }
  }
}
