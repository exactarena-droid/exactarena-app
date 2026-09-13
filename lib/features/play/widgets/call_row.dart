import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/models.dart';
import '../../../theme/terrace_theme.dart';
import '../../../theme/terrace_tokens.dart';
import '../../../widgets/widgets.dart';

/// One fixture in the "This week" list. Open fixtures show two compact score
/// steppers (− number +); kicked-off fixtures show the saved call + a points
/// pill and can't be edited.
class CallRow extends StatelessWidget {
  final RoundFixtureCall fixture;
  final Call call;
  final ValueChanged<int> onHome;
  final ValueChanged<int> onAway;

  const CallRow({
    super.key,
    required this.fixture,
    required this.call,
    required this.onHome,
    required this.onAway,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    final locked = f.isLocked;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          _Header(fixture: f),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TeamSide(team: f.fixture.homeTeam, alignEnd: false),
              ),
              if (locked) _LockedScore(call: f.myCall) else _Stepper(value: call.homeScore, onChanged: onHome),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–', style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
              if (locked) _LockedScore(call: f.myCall, away: true) else _Stepper(value: call.awayScore, onChanged: onAway),
              Expanded(
                child: _TeamSide(team: f.fixture.awayTeam, alignEnd: true),
              ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: 10),
            _LockedFooter(fixture: f),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final RoundFixtureCall fixture;
  const _Header({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    final kickoff = f.fixture.kickoffAt;
    final league = f.fixture.leagueName;
    return Row(
      children: [
        Expanded(
          child: Text(
            (league == null || league.isEmpty) ? 'Fixture' : league.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TerraceTextStyles.overline(context),
          ),
        ),
        const SizedBox(width: 8),
        if (f.isLocked)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, size: 12, color: t.textMuted),
              const SizedBox(width: 4),
              Text('Kicked off', style: TextStyle(color: t.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          )
        else if (kickoff != null)
          Text(
            DateFormat('EEE d MMM • HH:mm').format(kickoff.toLocal()),
            style: TextStyle(color: t.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class _TeamSide extends StatelessWidget {
  final Team? team;
  final bool alignEnd;
  const _TeamSide({required this.team, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    final crest = TeamCrest(team: team, size: 30);
    final name = Flexible(
      child: Text(
        team?.displayName ?? 'TBD',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [name, const SizedBox(width: 8), crest]
          : [crest, const SizedBox(width: 8), name],
    );
  }
}

/// A compact − number + score stepper.
class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceMuted,
        borderRadius: BorderRadius.circular(TerraceRadii.md),
        border: Border.all(color: t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: LucideIcons.plus,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value + 1);
            },
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TerraceTextStyles.scoreboard(context, size: 24),
            ),
          ),
          _StepButton(
            icon: LucideIcons.minus,
            enabled: value > 0,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value - 1);
            },
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _StepButton({required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: 30,
          child: Icon(icon, size: 16, color: enabled ? t.brand : t.textMuted),
        ),
      ),
    );
  }
}

/// A read-only score box shown for kicked-off fixtures.
class _LockedScore extends StatelessWidget {
  final Call? call;
  final bool away;
  const _LockedScore({required this.call, this.away = false});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final value = call == null ? '–' : '${away ? call!.awayScore : call!.homeScore}';
    return Container(
      width: 40,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceInset,
        borderRadius: BorderRadius.circular(TerraceRadii.md),
      ),
      child: Text(value, style: TerraceTextStyles.scoreboard(context, size: 24)),
    );
  }
}

/// Footer on a locked row: shows the actual result so far + a points pill.
class _LockedFooter extends StatelessWidget {
  final RoundFixtureCall fixture;
  const _LockedFooter({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    final hasResult = f.fixture.hasScore;
    return Row(
      children: [
        if (f.myCall == null)
          Text('No call made', style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w600))
        else
          Row(
            children: [
              Icon(LucideIcons.target, size: 13, color: t.textMuted),
              const SizedBox(width: 5),
              Text(
                'Your call ${f.myCall!.homeScore}–${f.myCall!.awayScore}',
                style: TextStyle(color: t.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        const Spacer(),
        if (hasResult)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Result ${f.fixture.homeScore}–${f.fixture.awayScore}',
              style: TextStyle(color: t.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        if (f.settled) _PointsPill(points: f.points ?? 0),
      ],
    );
  }
}

/// Points earned for a settled fixture. Green when the fan scored, neutral on 0.
class _PointsPill extends StatelessWidget {
  final int points;
  const _PointsPill({required this.points});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final scored = points > 0;
    final exact = points >= 5;
    final bg = scored ? t.brand : t.surfaceInset;
    final fg = scored ? t.textOnBrand : t.textMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 11, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TerraceRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(exact ? LucideIcons.sparkles : LucideIcons.check, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            '+$points',
            style: TerraceTextStyles.tableNum(context, size: 13, weight: FontWeight.w800, color: fg),
          ),
          const SizedBox(width: 2),
          Text('pts', style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
