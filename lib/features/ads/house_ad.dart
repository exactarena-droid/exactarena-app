import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../theme/terrace_tokens.dart';

// --- GOOGLE ADMOB CONFIGURATION ---
class AdMobConfig {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2213839288363676/4073808039'; // Android Banner
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2213839288363676/7518229023'; // iOS Banner
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-2213839288363676/4688317483'; // Android Interstitial
    } else if (Platform.isIOS) {
      return 'ca-app-pub-2213839288363676/2992092430'; // iOS Interstitial
    }
    return '';
  }
}

/// Admin-managed house banner ad OR Google AdMob Banner fallback.
class HouseAdBanner extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  const HouseAdBanner({super.key, this.margin = const EdgeInsets.fromLTRB(16, 12, 16, 4)});

  @override
  State<HouseAdBanner> createState() => _HouseAdBannerState();
}

class _HouseAdBannerState extends State<HouseAdBanner> {
  BannerAd? _adMobBanner;
  bool _isAdMobLoaded = false;

  void _loadAdMob(String adUnitId) {
    if (_adMobBanner != null) return;
    _adMobBanner = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isAdMobLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _adMobBanner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _adMobBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final config = ref.watch(appConfigProvider).valueOrNull;
        final isPremium = ref.watch(authControllerProvider).user?.isPremium ?? false;

        if (config == null || !config.adsEnabled || isPremium) {
          return const SizedBox.shrink();
        }

        final image = config.adBannerImage;
        final link = config.adBannerLink;

        // If admin uploaded a House Ad via Web Admin, show it first
        if (image != null && image.isNotEmpty) {
          return Padding(
            padding: widget.margin,
            child: GestureDetector(
              onTap: (link == null || link.isEmpty)
                  ? null
                  : () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TerraceRadii.lg),
                child: Stack(
                  children: [
                    CachedNetworkImage(imageUrl: image, width: double.infinity, fit: BoxFit.cover),
                    const Positioned(left: 8, top: 8, child: _AdTag()),
                  ],
                ),
              ),
            ),
          );
        }

        // Otherwise fallback to Google AdMob Banner
        final adUnitId = AdMobConfig.bannerAdUnitId;
        if (adUnitId.isNotEmpty) {
          _loadAdMob(adUnitId);
          if (_isAdMobLoaded && _adMobBanner != null) {
            return Padding(
              padding: widget.margin,
              child: Container(
                alignment: Alignment.center,
                width: _adMobBanner!.size.width.toDouble(),
                height: _adMobBanner!.size.height.toDouble(),
                child: AdWidget(ad: _adMobBanner!),
              ),
            );
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _AdTag extends StatelessWidget {
  const _AdTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
      child: const Text('AD',
          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
    );
  }
}

/// Shown at most once per app session (free users only).
final interstitialShownProvider = StateProvider<bool>((ref) => false);

/// Show the admin-managed full-screen pop-up ad OR Google AdMob Interstitial.
Future<void> maybeShowInterstitial(BuildContext context, WidgetRef ref) async {
  if (ref.read(interstitialShownProvider)) return;

  final config = ref.read(appConfigProvider).valueOrNull;
  final isPremium = ref.read(authControllerProvider).user?.isPremium ?? false;

  if (config == null || !config.adsEnabled || isPremium) return;

  final image = config.adInterstitialImage;
  final link = config.adInterstitialLink;

  // Mark as shown for this session
  ref.read(interstitialShownProvider.notifier).state = true;
  if (!context.mounted) return;

  // If admin uploaded a House Interstitial via Web Admin, show it first
  if (image != null && image.isNotEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(28),
        child: Stack(
          children: [
            GestureDetector(
              onTap: (link == null || link.isEmpty)
                  ? null
                  : () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
              child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            const Positioned(left: 12, top: 12, child: _AdTag()),
          ],
        ),
      ),
    );
    return;
  }

  // Otherwise fallback to Google AdMob Interstitial
  final adUnitId = AdMobConfig.interstitialAdUnitId;
  if (adUnitId.isNotEmpty) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }
}
