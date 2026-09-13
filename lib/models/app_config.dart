import 'json.dart';
import 'league.dart';

class AppConfig {
  final String appName;
  final int liveRefreshSeconds;
  final String? primaryColor;
  final String? logo;
  final String? supportEmail;
  final bool communityEnabled;
  final bool newsEnabled;
  final bool adsEnabled;
  final bool challengeEnabled;
  final String? supooraEmbedKey;
  final bool paymentsEnabled;
  final String? subscribeUrl;
  final String? adBannerImage;
  final String? adBannerLink;
  final String? adInterstitialImage;
  final String? adInterstitialLink;
  final List<League> featuredLeagues;

  const AppConfig({
    this.appName = 'Terrace',
    this.liveRefreshSeconds = 30,
    this.primaryColor,
    this.logo,
    this.supportEmail,
    this.communityEnabled = true,
    this.newsEnabled = true,
    this.adsEnabled = false,
    this.challengeEnabled = true,
    this.supooraEmbedKey,
    this.paymentsEnabled = false,
    this.subscribeUrl,
    this.adBannerImage,
    this.adBannerLink,
    this.adInterstitialImage,
    this.adInterstitialLink,
    this.featuredLeagues = const [],
  });

  /// True when a Supoora embed key is configured, so the support/live-chat
  /// entry point can be shown. Gates gracefully when no key is set.
  bool get hasLiveChat => (supooraEmbedKey ?? '').isNotEmpty;

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final app = asMap(j['app']) ?? const {};
    final branding = asMap(j['branding']) ?? const {};
    final features = asMap(j['features']) ?? const {};
    final support = asMap(j['support']) ?? const {};
    final payments = asMap(j['payments']) ?? const {};
    final ads = asMap(j['ads']) ?? const {};
    final adBanner = asMap(ads['banner']) ?? const {};
    final adInterstitial = asMap(ads['interstitial']) ?? const {};
    return AppConfig(
      appName: asString(app['name'], 'Terrace'),
      liveRefreshSeconds: asInt(app['live_refresh_seconds'], 30),
      primaryColor: asStringOrNull(branding['primary_color']),
      logo: asStringOrNull(branding['logo']),
      supportEmail: asStringOrNull(branding['support_email']),
      communityEnabled: asBool(features['community'], true),
      newsEnabled: asBool(features['news'], true),
      adsEnabled: asBool(features['ads_enabled']),
      challengeEnabled: asBool(features['challenge'], true),
      supooraEmbedKey: asStringOrNull(support['supoora_embed_key']),
      paymentsEnabled: asBool(payments['enabled']),
      subscribeUrl: asStringOrNull(payments['subscribe_url']),
      adBannerImage: asStringOrNull(adBanner['image']),
      adBannerLink: asStringOrNull(adBanner['link']),
      adInterstitialImage: asStringOrNull(adInterstitial['image']),
      adInterstitialLink: asStringOrNull(adInterstitial['link']),
      featuredLeagues: asMapList(j['featured_leagues']).map(League.fromJson).toList(),
    );
  }
}
