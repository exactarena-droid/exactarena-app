import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fixture.dart';
import '../theme/terrace_theme.dart';
import '../theme/terrace_tokens.dart';
import 'live_dot.dart';
import 'team_crest.dart';

/// The core scores list item: two team rows, a status column on the right, and
/// a thin LIVE accent rail when the match is in play.
class MatchCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback? onTap;
  final bool showLeague;

  const MatchCard({super.key, required this.fixture, this.onTap, this.showLeague = false});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;
    final live = f.isLive;
    final finished = f.isFinished;

    final homeWin = f.hasScore && f.homeScore! > f.awayScore!;
    final awayWin = f.hasScore && f.awayScore! > f.homeScore!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(TerraceRadii.xl),
        border: Border.all(color: live ? t.live.withValues(alpha: 0.4) : t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left status rail: green for live, otherwise quiet.
                Container(width: 3, color: live ? t.live : Colors.transparent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showLeague && f.league != null) ...[
                          Text(
                            f.league!.name.toUpperCase(),
                            style: TerraceTextStyles.overline(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _TeamRow(
                          team: f.homeTeam,
                          score: f.homeScore,
                          emphasised: homeWin,
                          dim: finished && awayWin,
                          showScore: f.hasScore,
                        ),
                        const SizedBox(height: 10),
                        _TeamRow(
                          team: f.awayTeam,
                          score: f.awayScore,
                          emphasised: awayWin,
                          dim: finished && homeWin,
                          showScore: f.hasScore,
                        ),
                      ],
                    ),
                  ),
                ),
                _StatusColumn(fixture: f),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final dynamic team; // Team?
  final int? score;
  final bool emphasised;
  final bool dim;
  final bool showScore;

  const _TeamRow({
    required this.team,
    required this.score,
    required this.emphasised,
    required this.dim,
    required this.showScore,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final color = dim ? t.textMuted : t.textPrimary;
    return Row(
      children: [
        TeamCrest(team: team, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team?.displayName ?? 'TBD',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
        if (showScore)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${score ?? 0}',
              style: TerraceTextStyles.tableNum(
                context,
                size: 17,
                weight: emphasised ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusColumn extends StatelessWidget {
  final Fixture fixture;
  const _StatusColumn({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final f = fixture;

    Widget content;
    if (f.isLive) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LiveDot(size: 8),
          const SizedBox(height: 6),
          Text(
            f.isHalftime ? 'HT' : (f.statusDetail ?? "${f.minute ?? 0}'"),
            style: TerraceTextStyles.mono(context, size: 12, weight: FontWeight.w700, color: t.live),
          ),
        ],
      );
    } else if (f.isFinished) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('FT', style: TerraceTextStyles.overline(context)),
        ],
      );
    } else if (f.status == FixtureStatus.postponed || f.status == FixtureStatus.canceled) {
      content = Text(
        f.status == FixtureStatus.postponed ? 'PP' : 'CAN',
        style: TerraceTextStyles.overline(context, color: t.danger),
      );
    } else {
      // Scheduled — show kickoff time.
      final ko = f.kickoffAt;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ko != null ? DateFormat('HH:mm').format(ko.toLocal()) : '--:--',
            style: TerraceTextStyles.mono(context, size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            ko != null ? DateFormat('d MMM').format(ko.toLocal()) : '',
            style: TerraceTextStyles.overline(context),
          ),
        ],
      );
    }

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: t.border)),
      ),
      child: Center(child: content),
    );
  }
}
