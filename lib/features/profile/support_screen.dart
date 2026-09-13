import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supoora_sdk/supoora_sdk.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../models/app_config.dart';
import '../../theme/terrace_theme.dart';
import '../../widgets/widgets.dart';

/// Live-chat support, powered by Supoora.
///
/// The Supoora embed key arrives from `/config` (`support.supoora_embed_key`)
/// so buyers can wire up their own workspace from the admin without an app
/// update. When no key is configured we gate gracefully and fall back to a
/// support-email prompt.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Live chat')),
      body: AsyncView<AppConfig>(
        value: config,
        loading: const Center(child: CircularProgressIndicator()),
        onRetry: () => ref.invalidate(appConfigProvider),
        data: (cfg) {
          if (!cfg.hasLiveChat) {
            return _ChatUnavailable(supportEmail: cfg.supportEmail);
          }
          return _SupooraChat(config: cfg);
        },
      ),
    );
  }
}

class _SupooraChat extends ConsumerWidget {
  final AppConfig config;
  const _SupooraChat({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final t = context.terrace;
    return Stack(
      children: [
        // Intro panel behind the floating chat bubble.
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: t.brandSubtle, shape: BoxShape.circle),
                  child: Icon(LucideIcons.headset, size: 34, color: t.brand),
                ),
                const SizedBox(height: 24),
                Text("We're here to help",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  user != null
                      ? 'Tap the chat button to talk to the Terrace team. We typically reply within minutes.'
                      : 'Tap the chat button below to start a conversation with the Terrace team.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        // Supoora drop-in widget: a floating bubble that opens a full chat
        // overlay with real-time messaging. Visitor identity (name/email) is
        // attached as metadata so agents see who the signed-in fan is.
        SupooraChatWidget(
          embedKey: config.supooraEmbedKey,
          baseUrl: 'https://api.supoora.com/api',
          primaryColor: t.brand,
          headerTitle: 'Terrace support',
          headerSubtitle: user?.name ?? 'We typically reply within minutes',
          welcomeMessage: user != null
              ? 'Hi ${user.name.split(' ').first}, how can we help?'
              : 'Hi! How can we help you today?',
        ),
      ],
    );
  }
}

class _ChatUnavailable extends StatelessWidget {
  final String? supportEmail;
  const _ChatUnavailable({this.supportEmail});

  @override
  Widget build(BuildContext context) {
    final email = supportEmail;
    return EmptyState(
      icon: LucideIcons.messageCircleOff,
      title: 'Live chat is offline',
      message: email != null && email.isNotEmpty
          ? 'Live chat is not available right now. Reach us at $email and we\'ll get back to you.'
          : 'Live chat is not available right now. Please try again later.',
    );
  }
}
