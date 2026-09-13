import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/auth_controller.dart';
import '../../data/repositories.dart';
import '../../models/poll.dart';
import '../../theme/terrace_theme.dart';
import '../../theme/terrace_tokens.dart';

/// Fan-opinion poll. Results are shown after voting (or when closed). This is
/// strictly opinion — fan opinion only (see COMPLIANCE.md).
class PollCard extends ConsumerStatefulWidget {
  final Poll poll;
  const PollCard({super.key, required this.poll});

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  late Poll _poll = widget.poll;
  bool _busy = false;

  bool get _revealed => _poll.hasVoted || _poll.isClosed;

  Future<void> _vote(int optionId) async {
    if (_busy || _poll.isClosed) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to share your opinion.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await ref.read(pollRepositoryProvider).vote(_poll.id, optionId);
      if (mounted) setState(() => _poll = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not record your vote. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16, color: t.brand),
              const SizedBox(width: 8),
              Text('FAN OPINION', style: TerraceTextStyles.overline(context, color: t.brand)),
              const Spacer(),
              if (_poll.isClosed)
                Text('Closed', style: TerraceTextStyles.overline(context)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_poll.question, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (final opt in _poll.options) ...[
            _PollOptionRow(
              option: opt,
              selected: _poll.myVoteOptionId == opt.id,
              revealed: _revealed,
              onTap: () => _vote(opt.id),
              busy: _busy,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          Text(
            '${_poll.votesCount} ${_poll.votesCount == 1 ? "vote" : "votes"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PollOptionRow extends StatelessWidget {
  final PollOption option;
  final bool selected;
  final bool revealed;
  final bool busy;
  final VoidCallback onTap;

  const _PollOptionRow({
    required this.option,
    required this.selected,
    required this.revealed,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final pct = (option.percentage.clamp(0, 100)) / 100.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TerraceRadii.md),
            border: Border.all(color: selected ? t.brand : t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (revealed)
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    color: selected
                        ? t.brand.withValues(alpha: 0.16)
                        : t.surfaceInset.withValues(alpha: 0.7),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(LucideIcons.checkCircle2, size: 16, color: t.brand),
                      ),
                    Expanded(
                      child: Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    if (revealed)
                      Text(
                        '${option.percentage.round()}%',
                        style: TerraceTextStyles.tableNum(context, size: 13, weight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
