import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Premium gradient button with press-scale animation.
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Gradient gradient;
  final double height;
  final List<BoxShadow>? shadows;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = AppTheme.blueGradient,
    this.height = 56,
    this.shadows,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => _c.forward() : null,
      onTapUp: enabled ? (_) => _c.reverse() : null,
      onTapCancel: () => _c.reverse(),
      onTap: enabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.55,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              boxShadow: enabled
                  ? (widget.shadows ?? AppTheme.shadowBlue)
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Soft premium card with consistent radius + shadow.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final Border? border;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.gradient,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppTheme.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: border ?? Border.all(color: AppTheme.border.withOpacity(0.6)),
        boxShadow: shadows ?? AppTheme.shadowSm,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Curved gradient header used on top of premium screens.
class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final double height;
  final Widget? bottom;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.height = 190,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + (bottom != null ? 44 : 0),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppTheme.rXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1565C0),
            blurRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 60,
            top: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                  if (bottom != null) ...[
                    const SizedBox(height: 14),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Staggered fade+slide entrance wrapper.
class Entrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const Entrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 26,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<double>(begin: widget.offsetY, end: 0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Premium empty state with icon + CTA.
class PremiumEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const PremiumEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.14),
                    AppTheme.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 40, color: AppTheme.primary.withOpacity(0.7)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 18),
              PremiumButton(
                label: ctaLabel!,
                onPressed: onCta,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill badge.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final IconData? icon;

  const Pill({
    super.key,
    required this.text,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title row with optional action.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps a home screen: Back navigates to the previous route when one exists;
/// only at the true root does the first press show a hint and the second
/// minimize the app. Never swallows Back while history exists, and never
/// exits while a previous screen is available.
///
/// Implementation note: go_router's popRoute() short-circuits at the root of
/// the stack and never consults PopScope there, so a PopScope-based guard can
/// never fire on a real device. Instead this registers a WidgetsBindingObserver
/// AFTER the Router's own back dispatcher: the router consumes every Back it
/// can handle (previous route, dialog, bottom sheet); only the Back presses the
/// router declines (genuine root) reach this observer.
class DoubleTapToExit extends StatefulWidget {
  final Widget child;
  final String message;
  const DoubleTapToExit({
    super.key,
    required this.child,
    this.message = 'Wapas back dabao app band karne ke liye',
  });

  @override
  State<DoubleTapToExit> createState() => _DoubleTapToExitState();
}

class _DoubleTapToExitState extends State<DoubleTapToExit> {
  DateTime? _lastBack;
  late final _RootBackObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = _RootBackObserver(_onRootBack);
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  /// Runs only for Back presses the router could not handle (no previous
  /// route, no open dialog/sheet). Returns true when consumed.
  Future<bool> _onRootBack() async {
    if (!mounted) return false;
    // Safety net: if history somehow exists, don't touch it.
    if (GoRouter.of(context).canPop()) return false;
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      return false; // let the system minimize/exit the app
    }
    _lastBack = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(widget.message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Forwards unconsumed system-Back presses to [onBack].
class _RootBackObserver extends WidgetsBindingObserver {
  final Future<bool> Function() onBack;
  _RootBackObserver(this.onBack);

  @override
  Future<bool> didPopRoute() => onBack();
}
