import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────── PremiumButton ───────────────────────────────
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
                        Icon(widget.icon, color: Colors.white, size: 20),
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

// ─────────────────────────────── PremiumCard ─────────────────────────────────
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

// ─────────────────────────────── PremiumHeader ───────────────────────────────
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
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppTheme.rXl)),
      ),
      child: Stack(
        children: [
          Positioned(
              right: -40,
              top: -40,
              child: _circle(160, Colors.white.withOpacity(0.08))),
          Positioned(
              right: 60,
              top: 40,
              child: _circle(90, Colors.white.withOpacity(0.06))),
          Positioned(
              left: -30,
              bottom: -50,
              child: _circle(140, AppTheme.gold.withOpacity(0.12))),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4)),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(subtitle!,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13.5)),
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

  Widget _circle(double s, Color c) => Container(
      width: s,
      height: s,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ─────────────────────────────── ShimmerBox ──────────────────────────────────
/// Animated shimmer skeleton — professional loading state like Uber/LinkedIn.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox(
      {super.key,
      required this.width,
      required this.height,
      this.radius = 10});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [
              Color(0xFFE8EDF5),
              Color(0xFFF6F8FC),
              Color(0xFFE8EDF5),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton trip card shown while loading lists.
class SkeletonTripCard extends StatelessWidget {
  const SkeletonTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ShimmerBox(width: 120, height: 14, radius: 7),
            const Spacer(),
            const ShimmerBox(width: 64, height: 24, radius: 12),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const ShimmerBox(width: 16, height: 16, radius: 8),
            const SizedBox(width: 10),
            const ShimmerBox(width: 200, height: 13, radius: 6),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const ShimmerBox(width: 16, height: 16, radius: 8),
            const SizedBox(width: 10),
            const ShimmerBox(width: 160, height: 13, radius: 6),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const ShimmerBox(width: 80, height: 12, radius: 6),
            const Spacer(),
            const ShimmerBox(width: 56, height: 20, radius: 8),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────── AppBottomNav ────────────────────────────────
/// Consistent animated bottom navigation bar used on all main screens.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDriver;

  const AppBottomNav(
      {super.key, required this.currentIndex, this.isDriver = false});

  @override
  Widget build(BuildContext context) {
    final items = isDriver
        ? const [
            _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
            _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined,
                'Bookings'),
            _NavItem(Icons.account_balance_wallet_rounded,
                Icons.account_balance_wallet_outlined, 'Wallet'),
            _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
          ]
        : const [
            _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
            _NavItem(Icons.add_circle_rounded,
                Icons.add_circle_outline_rounded, 'Book'),
            _NavItem(Icons.history_rounded, Icons.history, 'Trips'),
            _NavItem(
                Icons.person_rounded, Icons.person_outlined, 'Profile'),
          ];

    final routes = isDriver
        ? const [
            '/driver',
            '/driver/requests',
            '/driver/wallet',
            '/driver/profile'
          ]
        : const [
            '/customer',
            '/customer/booking',
            '/customer/history',
            '/customer/profile'
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: AppTheme.border.withOpacity(0.8))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () {
                  if (!selected) context.go(routes[i]);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? items[i].activeIcon
                            : items[i].icon,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textTertiary,
                        size: 22,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        child: selected
                            ? Row(children: [
                                const SizedBox(width: 6),
                                Text(items[i].label,
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon, icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ─────────────────────────────── StatusBadge ─────────────────────────────────
/// Color-coded booking status chip.
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;

  const StatusBadge({super.key, required this.text, required this.type});

  factory StatusBadge.fromStatus(String status) {
    switch (status) {
      case 'completed':
        return const StatusBadge(text: 'Completed', type: StatusType.success);
      case 'cancelled':
        return const StatusBadge(text: 'Cancelled', type: StatusType.error);
      case 'started':
      case 'ongoing':
        return const StatusBadge(
            text: 'In Progress', type: StatusType.info);
      case 'arrived':
        return const StatusBadge(
            text: 'Driver Arrived', type: StatusType.warning);
      case 'driver_assigned':
        return const StatusBadge(
            text: 'Driver Assigned', type: StatusType.info);
      case 'open_for_bids':
        return const StatusBadge(
            text: 'Bids Open', type: StatusType.warning);
      default:
        return const StatusBadge(text: 'Pending', type: StatusType.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg, fg;
    final IconData icon;
    switch (type) {
      case StatusType.success:
        bg = AppTheme.successSoft;
        fg = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case StatusType.error:
        bg = AppTheme.errorSoft;
        fg = AppTheme.error;
        icon = Icons.cancel_rounded;
        break;
      case StatusType.warning:
        bg = AppTheme.warningSoft;
        fg = AppTheme.warning;
        icon = Icons.schedule_rounded;
        break;
      case StatusType.info:
        bg = AppTheme.infoSoft;
        fg = AppTheme.info;
        icon = Icons.directions_car_rounded;
        break;
      default:
        bg = AppTheme.surfaceTint;
        fg = AppTheme.textSecondary;
        icon = Icons.radio_button_unchecked;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

enum StatusType { success, error, warning, info, neutral }

// ─────────────────────────────── InfoRow ─────────────────────────────────────
/// Icon + label + value row used inside detail cards.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Entrance ────────────────────────────────────
class Entrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const Entrance(
      {super.key,
      required this.child,
      this.delayMs = 0,
      this.offsetY = 26});

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
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<double>(begin: widget.offsetY, end: 0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs),
        () { if (mounted) _c.forward(); });
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
        child:
            Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────── PremiumEmpty ────────────────────────────────
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primary.withOpacity(0.12),
                  AppTheme.primary.withOpacity(0.04),
                ]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 44, color: AppTheme.primary.withOpacity(0.65)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.55),
                textAlign: TextAlign.center),
            if (ctaLabel != null) ...[
              const SizedBox(height: 22),
              PremiumButton(label: ctaLabel!, onPressed: onCta, height: 50),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────── Pill ────────────────────────────────────────
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final IconData? icon;

  const Pill(
      {super.key,
      required this.text,
      required this.color,
      required this.bg,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────── SectionTitle ────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle(
      {super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppTheme.textPrimary)),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
      ],
    );
  }
}

// ─────────────────────────────── DoubleTapToExit ─────────────────────────────

// ─────────────────────────────────────── SkeletonDetailCard ─────────────────────────────────────────────
/// Skeleton detail card shown while loading detail/profile screens.
class SkeletonDetailCard extends StatelessWidget {
  const SkeletonDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            ShimmerBox(width: 18, height: 18, radius: 9),
            const SizedBox(width: 12),
            ShimmerBox(width: 80, height: 13, radius: 6),
            const SizedBox(width: 12),
            ShimmerBox(width: 140 - i * 10.0, height: 13, radius: 6),
          ]),
        )),
      ),
    );
  }
}
class DoubleTapToExit extends StatefulWidget {
  final Widget child;
  final String message;
  const DoubleTapToExit({
    super.key,
    required this.child,
    this.message = 'Press back again to exit',
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

  Future<bool> _onRootBack() async {
    if (!mounted) return false;
    if (GoRouter.of(context).canPop()) return false;
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      return false;
    }
    _lastBack = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(widget.message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RootBackObserver extends WidgetsBindingObserver {
  final Future<bool> Function() onBack;
  _RootBackObserver(this.onBack);

  @override
  Future<bool> didPopRoute() => onBack();
}
