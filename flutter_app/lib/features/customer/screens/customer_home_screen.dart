import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../core/l10n/app_strings.dart";
import "../../../core/theme/app_theme.dart";
import "../../../core/widgets/premium.dart";
import '../../../core/routes/nav.dart';

/// 2026-style customer home: 3D tilt trip cards, staggered entrance,
/// glowing gradients and a premium hero header.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Animation<double> _fade(int i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _enter,
          curve: Interval(i * 0.12, 0.45 + i * 0.12, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _slide(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _enter,
          curve: Interval(i * 0.12, 0.45 + i * 0.12, curve: Curves.easeOutCubic),
        ),
      );

  @override
  Widget build(BuildContext context) => DoubleTapToExit(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: ValueListenableBuilder<String>(
            valueListenable: AppLang.current,
            builder: (_, __, ___) => CustomScrollView(
              slivers: [
                _hero(context),
                SliverToBoxAdapter(child: _body(context)),
              ],
            ),
          ),
          bottomNavigationBar: _bottomNav(context),
        ),
      );

  SliverAppBar _hero(BuildContext ctx) => SliverAppBar(
        expandedHeight: 215,
        pinned: true,
        backgroundColor: AppTheme.primaryDeep,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
            ),
            child: Stack(
              children: [
                // soft decorative blobs
                Positioned(
                  right: -40,
                  top: -30,
                  child: _blob(160, Colors.white.withOpacity(0.08)),
                ),
                Positioned(
                  left: -30,
                  bottom: -50,
                  child: _blob(130, AppTheme.gold.withOpacity(0.10)),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25)),
                              ),
                              child: const Icon(Icons.directions_car,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 10),
                            const Text("Namaste India",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                            const Spacer(),
                            _iconBtn(Icons.notifications_outlined, () => Nav.go(ctx, "/customer/notifications")),
                            const SizedBox(width: 8),
                            _iconBtn(Icons.wallet_outlined,
                                () => Nav.go(ctx, "/customer/wallet")),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(tr("tagline"),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(tr("taglineSub"),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Nav.push(ctx, "/customer/booking",
                              extra: {"type": "outstation"}),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              enabled: false,
                              decoration: InputDecoration(
                                hintText: tr("searchHint"),
                                hintStyle:
                                    const TextStyle(fontSize: 14),
                                prefixIcon: const Icon(Icons.search,
                                    color: Color(0xFF3949AB)),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _blob(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _iconBtn(IconData i, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Icon(i, color: Colors.white, size: 20),
        ),
      );

  Widget _body(BuildContext ctx) {
    final cards = [
      _TripKind(tr("oneWay"), tr("oneWaySub"), Icons.flight_takeoff,
          [const Color(0xFF1565C0), const Color(0xFF42A5F5)], "outstation"),
      _TripKind(tr("roundTrip"), tr("roundTripSub"), Icons.sync_alt,
          [const Color(0xFF2E7D32), const Color(0xFF66BB6A)], "round"),
      _TripKind(tr("local"), tr("localSub"), Icons.location_city,
          [const Color(0xFFE65100), const Color(0xFFFFA726)], "local"),
      _TripKind(tr("bid"), tr("bidSub"), Icons.gavel,
          [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)], "bid"),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr("bookRide"),
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tr("chooseTrip"),
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemCount: cards.length,
            itemBuilder: (c, i) {
              final k = cards[i];
              return FadeTransition(
                opacity: _fade(i),
                child: SlideTransition(
                  position: _slide(i),
                  child: _TiltCard(
                    glow: k.colors[0],
                    onTap: () => Nav.push(ctx, "/customer/booking",
                        extra: {"type": k.type}),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: k.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: k.colors[0].withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // top gloss
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.22),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.topCenter,
                                  end: const Alignment(0, 0.45),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.35)),
                                  ),
                                  child: Icon(k.icon,
                                      color: Colors.white, size: 27),
                                ),
                                const Spacer(),
                                Text(k.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(k.subtitle,
                                    style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.85),
                                        fontSize: 11.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          // Available Cars & Drivers (PDF P23) — online drivers dekho
          FadeTransition(
            opacity: _fade(3),
            child: SlideTransition(
              position: _slide(3),
              child: GestureDetector(
                onTap: () => Nav.push(ctx, "/customer/cars"),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF00695C),
                      Color(0xFF26A69A)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF26A69A).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.directions_car,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Available Cars",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            SizedBox(height: 4),
                            Text("See online drivers, hire directly",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeTransition(
            opacity: _fade(3),
            child: SlideTransition(
              position: _slide(3),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF1A237E),
                    Color(0xFF3949AB)
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3949AB).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr("popularRoutes"),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text("Ahmedabad • Surat • Vadodara",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Nav.push(ctx, "/customer/booking",
                          extra: {"type": "outstation"}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(tr("book"),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _trust(Icons.verified_user, tr("safe")),
              _trust(Icons.access_time, "24/7"),
              _trust(Icons.currency_rupee, tr("fairFare")),
              _trust(Icons.star, "Rated 4.8"),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _trust(IconData i, String l) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Icon(i, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(l,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _bottomNav(BuildContext ctx) => const AppBottomNav(currentIndex: 0, isDriver: false);
}

class _TripKind {
  final String title, subtitle, type;
  final IconData icon;
  final List<Color> colors;
  const _TripKind(this.title, this.subtitle, this.icon, this.colors, this.type);
}

/// Card that tilts in 3D following the finger, springing back on release.
class _TiltCard extends StatefulWidget {
  final Widget child;
  final Color glow;
  final VoidCallback onTap;
  const _TiltCard(
      {required this.child, required this.glow, required this.onTap});

  @override
  State<_TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<_TiltCard>
    with SingleTickerProviderStateMixin {
  double _rx = 0, _ry = 0, _scale = 1;
  late final AnimationController _spring;
  Animation<double>? _ax, _ay, _as;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _spring.addListener(_onTick);
  }

  void _onTick() {
    if (_ax == null) return;
    setState(() {
      _rx = _ax!.value;
      _ry = _ay!.value;
      _scale = _as!.value;
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _update(Offset local, Size size) {
    _spring.stop();
    _ax = _ay = _as = null;
    setState(() {
      _ry = ((local.dx / size.width) - 0.5).clamp(-0.6, 0.6) * 0.55;
      _rx = -((local.dy / size.height) - 0.5).clamp(-0.6, 0.6) * 0.55;
      _scale = 0.96;
    });
  }

  void _release() {
    _ax = Tween(begin: _rx, end: 0.0).animate(
        CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
    _ay = Tween(begin: _ry, end: 0.0).animate(
        CurvedAnimation(parent: _spring, curve: Curves.elasticOut));
    _as = Tween(begin: _scale, end: 1.0).animate(
        CurvedAnimation(parent: _spring, curve: Curves.easeOutBack));
    _spring
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onPanDown: (d) {
          final box = context.findRenderObject() as RenderBox;
          _update(box.globalToLocal(d.globalPosition), box.size);
        },
        onPanUpdate: (d) {
          final box = context.findRenderObject() as RenderBox;
          _update(box.globalToLocal(d.globalPosition), box.size);
        },
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(_rx)
            ..rotateY(_ry)
            ..scale(_scale, _scale, _scale),
          child: widget.child,
        ),
      );
}
