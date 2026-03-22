import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ───────────────────────────────────────────────
class NomadsColors {
  static const primary = Color(0xFF1a56db);
  static const primaryLight = Color(0xFFEBF0FF);
  static const success = Color(0xFF10b981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEF2F2);
  static const surface = Color(0xFFF9FAFB);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
}

class NomadsSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class NomadsRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const full = 100.0;
}

// ─── Theme ───────────────────────────────────────────────────────
ThemeData nomadsTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: NomadsColors.primary,
      surface: NomadsColors.surface,
    ),
    scaffoldBackgroundColor: NomadsColors.surface,
    textTheme: GoogleFonts.interTextTheme(),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: NomadsColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: NomadsColors.primaryLight,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: NomadsColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NomadsRadius.lg),
        side: const BorderSide(color: NomadsColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NomadsColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NomadsRadius.md)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NomadsColors.textPrimary,
        side: const BorderSide(color: NomadsColors.border),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NomadsRadius.md)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(NomadsRadius.md), borderSide: const BorderSide(color: NomadsColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NomadsRadius.md), borderSide: const BorderSide(color: NomadsColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(NomadsRadius.md), borderSide: const BorderSide(color: NomadsColors.primary, width: 1.5)),
    ),
    dividerTheme: const DividerThemeData(color: NomadsColors.border, space: 1),
  );
}

// ─── Shared Widgets ──────────────────────────────────────────────

/// Clean card container — soft border, no shadow noise
class NCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const NCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(NomadsSpacing.md),
      decoration: BoxDecoration(
        color: NomadsColors.card,
        borderRadius: BorderRadius.circular(NomadsRadius.lg),
        border: Border.all(color: NomadsColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Hero amount display — large, bold, aligned
class AmountDisplay extends StatelessWidget {
  final String currency;
  final double amount;
  final Color? color;
  final double fontSize;
  final bool showSign;

  const AmountDisplay({
    super.key,
    required this.currency,
    required this.amount,
    this.color,
    this.fontSize = 32,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final sign = showSign ? (isPositive ? '+' : '-') : '';
    final parts = amount.abs().toStringAsFixed(2).split('.');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('$sign$currency ', style: TextStyle(
          fontSize: fontSize * 0.5,
          fontWeight: FontWeight.w500,
          color: color ?? NomadsColors.textSecondary,
        )),
        Text(parts[0], style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color ?? NomadsColors.textPrimary,
        )),
        Text('.${parts[1]}', style: TextStyle(
          fontSize: fontSize * 0.6,
          fontWeight: FontWeight.w500,
          color: color ?? NomadsColors.textMuted,
        )),
      ],
    );
  }
}

/// Status chip — consistent across app
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg, fg;
    if (lower.contains('complet') || lower.contains('success') || lower == 'active' || lower == 'executed') {
      bg = NomadsColors.successLight; fg = NomadsColors.success;
    } else if (lower.contains('pend') || lower.contains('hold')) {
      bg = NomadsColors.warningLight; fg = NomadsColors.warning;
    } else if (lower.contains('fail') || lower.contains('cancel') || lower.contains('reject')) {
      bg = NomadsColors.errorLight; fg = NomadsColors.error;
    } else {
      bg = const Color(0xFFF3F4F6); fg = NomadsColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NomadsRadius.full)),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// Primary CTA button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const PrimaryButton({super.key, required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label),
      ),
    );
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NomadsSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: NomadsColors.textMuted),
          const SizedBox(height: NomadsSpacing.md),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NomadsColors.textSecondary)),
          if (subtitle != null) ...[
            const SizedBox(height: NomadsSpacing.sm),
            Text(subtitle!, style: const TextStyle(fontSize: 13, color: NomadsColors.textMuted), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: NomadsSpacing.lg),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ]),
      ),
    );
  }
}

/// Detail row for confirmation/receipt screens
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const DetailRow({super.key, required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: NomadsColors.textMuted)),
        Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
