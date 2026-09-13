import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_providers.dart';
import '../../models/article.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';
import 'news_screen.dart' show ArticleHero;

class ArticleDetailScreen extends ConsumerWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleDetailProvider(slug));
    return Scaffold(
      body: AsyncView(
        value: article,
        loading: const Center(child: CircularProgressIndicator()),
        onRetry: () => ref.invalidate(articleDetailProvider(slug)),
        data: (a) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 240,
              flexibleSpace: FlexibleSpaceBar(
                background: ArticleHero(article: a),
              ),
            ),
            SliverToBoxAdapter(child: _ArticleBody(article: a)),
          ],
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  final Article article;
  const _ArticleBody({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final a = article;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (a.category != null)
                Text(a.category!.name.toUpperCase(),
                    style: TerraceTextStyles.overline(context, color: t.brand)),
              const Spacer(),
              if (a.isPremium) const PremiumBadge(),
              if (a.isSponsored) ...[
                const SizedBox(width: 6),
                SponsoredChip(sponsor: a.sponsorName),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(a.title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              if (a.author != null) ...[
                InitialAvatar(
                  imageUrl: a.author!.avatar,
                  initials: _authorInitials(a.author!.name),
                  size: 32,
                  seed: a.author!.id ?? 0,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.author != null)
                      Text(a.author!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(
                      [
                        if (a.publishedAt != null) DateFormat('d MMM y').format(a.publishedAt!.toLocal()),
                        if (a.readingMinutes > 0) '${a.readingMinutes} min read',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: t.border, height: 32),
          if (a.excerpt != null) ...[
            Text(a.excerpt!, style: TerraceTextStyles.serifLead(context)),
            const SizedBox(height: 20),
          ],
          if (a.isLocked || a.body == null || a.body!.isEmpty)
            _PremiumLockCard(locked: a.isLocked)
          else
            _SerifBody(body: a.body!),
          if (!a.isLocked && a.sourceUrl != null && a.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SourceButton(name: a.sourceName, url: a.sourceUrl!),
          ],
        ],
      ),
    );
  }

  static String _authorInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }
}

/// Opens the original article at its source (for ingested news headlines).
class _SourceButton extends StatelessWidget {
  final String? name;
  final String url;
  const _SourceButton({required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return OutlinedButton.icon(
      onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      icon: const Icon(LucideIcons.externalLink, size: 16),
      label: Text('Read the full article at ${name ?? 'the source'}'),
      style: OutlinedButton.styleFrom(
        foregroundColor: t.brand,
        side: BorderSide(color: t.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Renders the article body. Plain-text paragraphs split on blank lines, rendered
/// in Fraunces for the magazine feel.
class _SerifBody extends StatelessWidget {
  final String body;
  const _SerifBody({required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs) ...[
          Text(p.trim(), style: TerraceTextStyles.serifBody(context)),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _PremiumLockCard extends ConsumerWidget {
  final bool locked;
  const _PremiumLockCard({required this.locked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accent.withValues(alpha: 0.10), t.surface],
        ),
        borderRadius: BorderRadius.circular(TerraceRadii.xl2),
        border: Border.all(color: t.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(LucideIcons.lock, color: t.accent, size: 24),
          ),
          const SizedBox(height: 16),
          Text('Premium article', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'This in-depth piece is part of Terrace Premium. Subscribe to read the full story and unlock ad-free reading.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/plans'),
            icon: const Icon(LucideIcons.crown, size: 18),
            label: const Text('See premium plans'),
            style: FilledButton.styleFrom(backgroundColor: t.accent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
