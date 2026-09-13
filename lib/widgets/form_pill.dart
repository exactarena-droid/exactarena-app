import 'package:flutter/material.dart';

import '../theme/terrace_theme.dart';

/// A single W / D / L result chip. State uses letter + color + shape so it
/// never relies on color alone (accessibility).
class FormPill extends StatelessWidget {
  final String result; // 'W' | 'D' | 'L'
  final double size;
  const FormPill({super.key, required this.result, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final t = context.terrace;
    final r = result.toUpperCase();
    final (bg, fg) = switch (r) {
      'W' => (t.success, Colors.white),
      'L' => (t.danger, Colors.white),
      _ => (t.surfaceInset, t.textSecondary),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        r.isEmpty ? '–' : r,
        style: TextStyle(
          color: fg,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A horizontal run of recent form pills (most recent last).
class FormRow extends StatelessWidget {
  final List<String> form;
  final double size;
  final int max;
  const FormRow({super.key, required this.form, this.size = 22, this.max = 5});

  @override
  Widget build(BuildContext context) {
    final items = form.length > max ? form.sublist(form.length - max) : form;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          FormPill(result: items[i], size: size),
        ],
      ],
    );
  }
}
