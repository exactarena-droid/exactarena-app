import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../models/article.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';
import '../../widgets/widgets.dart';
import '../ads/house_ad.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    // All news is sport news — no category filter.
    final feed = ref.watch(newsFeedProvider(null));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          const SliverAppBar(pinned: true, floating: true, title: Text('News')),
        ],
        body: RefreshIndicator(
          color: context.terrace.brand,
          onRefresh: () => ref.refresh(newsFeedProvider(null).future),
          child: AsyncView(
            value: feed,
            loading: const ListSkeleton(),
            onRetry: () => ref.invalidate(newsFeedProvider(null)),
            data: (articles) {
              if (articles.isEmpty) {
                return ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    assetPath: 'assets/onboarding/empty-news.svg',
                    title: 'No articles yet',
                    message: 'The latest sport headlines will appear here.',
                  ),
                ]);
              }
              final featured = articles.first;
              final rest = articles.skip(1).toList();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const HouseAdBanner(),
                  _FeaturedCard(article: featured),
                  for (final a in rest) _ArticleRow(article: a),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Large editorial hero for the top article.
class _FeaturedCard extends StatelessWidget {
  final Article article;
  const _FeaturedCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TerraceRadii.xl2),
          onTap: () => context.push('/article/${article.slug}'),
          child: Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(TerraceRadii.xl2),
              border: Border.all(color: t.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ArticleHero(article: article),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (article.category != null)
                            Text(article.category!.name.toUpperCase(),
                                style: TerraceTextStyles.overline(context, color: t.brand)),
                          const Spacer(),
                          if (article.isPremium) const PremiumBadge(compact: true),
                          if (article.isSponsored) ...[
                            const SizedBox(width: 6),
                            SponsoredChip(sponsor: article.sponsorName),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(article.title, style: Theme.of(context).textTheme.headlineMedium),
                      if (article.excerpt != null) ...[
                        const SizedBox(height: 6),
                        Text(article.excerpt!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 10),
                      _Meta(article: article),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final Article article;
  const _ArticleRow({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/article/${article.slug}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (article.category != null)
                          Flexible(
                            child: Text(article.category!.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TerraceTextStyles.overline(context, color: t.brand)),
                          ),
                        if (article.isPremium) ...[
                          const SizedBox(width: 8),
                          const PremiumBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, height: 1.25)),
                    const SizedBox(height: 8),
                    _Meta(article: article),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(TerraceRadii.md),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: ArticleHero(article: article),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final Article article;
  const _Meta({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final parts = <String>[];
    if (article.author != null) parts.add(article.author!.name);
    if (article.publishedAt != null) {
      parts.add(DateFormat('d MMM').format(article.publishedAt!.toLocal()));
    }
    if (article.readingMinutes > 0) parts.add('${article.readingMinutes} min read');
    return Row(
      children: [
        Icon(LucideIcons.clock, size: 12, color: t.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(parts.join(' · '),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Article hero image with a tasteful gradient placeholder fallback.
class ArticleHero extends StatelessWidget {
  final Article article;
  const ArticleHero({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final hero = article.heroImage;
    if (hero != null && hero.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: hero,
        fit: BoxFit.cover,
        placeholder: (context, url) => _Placeholder(article: article),
        errorWidget: (context, url, error) => _Placeholder(article: article),
      );
    }
    return _Placeholder(article: article);
  }
}

class _Placeholder extends StatelessWidget {
  final Article article;
  const _Placeholder({required this.article});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.brand, t.brandHover],
        ),
      ),
      child: Center(
        child: Icon(LucideIcons.newspaper, color: Colors.white.withValues(alpha: 0.4), size: 32),
      ),
    );
  }
}
