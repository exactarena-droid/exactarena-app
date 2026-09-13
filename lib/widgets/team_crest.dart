import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/team.dart';
import '../theme/terrace_theme.dart';
import '../theme/terrace_tokens.dart';

/// Team crest with a graceful, tasteful fallback: an initials badge on a
/// deterministic warm-tinted surface. Never renders a broken image.
class TeamCrest extends StatelessWidget {
  final Team? team;
  final double size;

  const TeamCrest({super.key, required this.team, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final logo = team?.logo;
    if (logo != null && logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: CachedNetworkImage(
          imageUrl: logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholder: (context, url) => _Fallback(team: team, size: size),
          errorWidget: (context, url, error) => _Fallback(team: team, size: size),
        ),
      );
    }
    return _Fallback(team: team, size: size);
  }
}

class _Fallback extends StatelessWidget {
  final Team? team;
  final double size;
  const _Fallback({required this.team, required this.size});

  // A small warm palette keyed off the team id so crests stay stable + varied.
  static const _tints = [
    [TerraceColors.pitch600, TerraceColors.pitch800],
    [TerraceColors.floodlight600, TerraceColors.floodlight800],
    [TerraceColors.stone600, TerraceColors.stone800],
    [TerraceColors.info500, TerraceColors.info600],
    [TerraceColors.rose500, TerraceColors.rose600],
    [TerraceColors.pitch500, TerraceColors.pitch700],
  ];

  @override
  Widget build(BuildContext context) {
    final id = team?.id ?? 0;
    final pair = _tints[id % _tints.length];
    final initials = team?.initials ?? '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(
          colors: pair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Generic circular avatar fallback (users/authors) — initials on warm surface.
class InitialAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final int seed;

  const InitialAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 36,
    this.seed = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _circle(t.brandSubtle, t.brand),
          errorWidget: (context, url, error) => _circle(t.brandSubtle, t.brand),
        ),
      );
    }
    return _circle(t.brandSubtle, t.brand);
  }

  Widget _circle(Color bg, Color fg) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Text(
          initials,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.38,
          ),
        ),
      );
}
