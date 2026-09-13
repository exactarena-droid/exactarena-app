import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/app_providers.dart';
import '../../data/auth_controller.dart';
import '../../data/repositories.dart';
import '../../theme/terrace_theme.dart';
import '../../widgets/widgets.dart';
import 'post_tile.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  final int fixtureId;
  const ThreadScreen({super.key, required this.fixtureId});

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join the conversation.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(communityRepositoryProvider).reply(widget.fixtureId, body: text);
      _controller.clear();
      ref.invalidate(fixtureThreadProvider(widget.fixtureId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final thread = ref.watch(fixtureThreadProvider(widget.fixtureId));
    return Scaffold(
      appBar: AppBar(title: const Text('Match thread')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: t.brand,
              onRefresh: () => ref.refresh(fixtureThreadProvider(widget.fixtureId).future),
              child: AsyncView(
                value: thread,
                loading: const Center(child: CircularProgressIndicator()),
                onRetry: () => ref.invalidate(fixtureThreadProvider(widget.fixtureId)),
                data: (posts) {
                  if (posts.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 60),
                      EmptyState(
                        icon: LucideIcons.messageCircle,
                        title: 'No posts yet',
                        message: 'Start the match-day conversation below.',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: posts.length,
                    separatorBuilder: (context, _) => Divider(height: 1, color: t.border),
                    itemBuilder: (context, i) => PostTile(post: posts[i]),
                  );
                },
              ),
            ),
          ),
          _Composer(controller: _controller, sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}

class _Composer extends ConsumerWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.terrace;
    final signedIn = ref.watch(currentUserProvider) != null;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: signedIn
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Share your view on the match…',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: FilledButton(
                        onPressed: sending ? null : onSend,
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: const CircleBorder()),
                        child: sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.send, size: 18),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Sign in to join the conversation.',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
