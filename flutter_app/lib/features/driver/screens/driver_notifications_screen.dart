import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";
import '../../../core/routes/nav.dart';

/// P27 (Travel edition) — Driver notifications with All / Bids / Payouts tabs.
class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});
  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _NItem {
  final IconData icon;
  final Color color;
  final String kind; // bid | payout | info
  final String title;
  final String subtitle;
  final String time;
  final String? route;
  _NItem(
      {required this.icon,
      required this.color,
      required this.kind,
      required this.title,
      required this.subtitle,
      required this.time,
      this.route});
}

class _DriverNotificationsScreenState
    extends State<DriverNotificationsScreen> {
  bool _loading = true;
  List<_NItem> _items = [];
  String _tab = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  String _ago(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = DateTime.now().difference(dt);
      if (d.inMinutes < 1) return 'now';
      if (d.inMinutes < 60) return '${d.inMinutes}m ago';
      if (d.inHours < 24) return '${d.inHours}h ago';
      return '${d.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = <_NItem>[];
    try {
      final h = await _headers();
      final base = AppConfig.apiBaseUrl;
      final results = await Future.wait([
        http.get(Uri.parse("$base/bookings/available"), headers: h),
        http.get(Uri.parse("$base/bookings/driver/my"), headers: h),
        http.get(Uri.parse("$base/subscriptions/status"), headers: h),
        http.get(Uri.parse("$base/drivers/wallet"), headers: h),
      ]);
      if (!mounted) return;

      if (results[0].statusCode == 200) {
        final a = jsonDecode(results[0].body) as Map<String, dynamic>;
        for (final e in ((a["bookings"] as List?) ?? []).take(5)) {
          final b = Map<String, dynamic>.from(e as Map);
          final from = (b["pickup"] is Map ? b["pickup"]["address"] : '') ?? '';
          final to = (b["drop"] is Map ? b["drop"]["address"] : '') ?? '';
          final fare = b["estimatedFare"] ?? b["finalFare"] ?? '';
          items.add(_NItem(
              icon: Icons.gavel_rounded,
              color: AppTheme.goldDeep,
              kind: 'bid',
              title: 'New bid request',
              subtitle: '$from → $to • ₹$fare',
              time: _ago(b["createdAt"]?.toString()),
              route: '/driver'));
        }
      }

      if (results[1].statusCode == 200) {
        final m = jsonDecode(results[1].body) as Map<String, dynamic>;
        for (final e in ((m["bookings"] as List?) ?? []).take(5)) {
          final b = Map<String, dynamic>.from(e as Map);
          final status = b["status"]?.toString() ?? '';
          final id = b["_id"]?.toString();
          final ts = (b["updatedAt"] ?? b["createdAt"])?.toString();
          if (status == 'driver_assigned') {
            items.add(_NItem(
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                kind: 'bid',
                title: 'Booking confirmed',
                subtitle: 'Reach the pickup point',
                time: _ago(ts),
                route: id == null ? null : '/driver/my-booking/$id'));
          } else if (status == 'completed') {
            final fare = b["finalFare"] ?? b["estimatedFare"] ?? '';
            items.add(_NItem(
                icon: Icons.payments_rounded,
                color: AppTheme.success,
                kind: 'payout',
                title: 'Trip complete • ₹$fare',
                subtitle: 'Added to wallet',
                time: _ago(ts),
                route: '/driver/earnings'));
          }
        }
      }

      if (results[2].statusCode == 200) {
        final s = jsonDecode(results[2].body) as Map<String, dynamic>;
        if (s["active"] == true && s["endsAt"] != null) {
          try {
            final ends = DateTime.parse(s["endsAt"].toString()).toLocal();
            final days = ends.difference(DateTime.now()).inDays;
            if (days <= 3) {
              items.add(_NItem(
                  icon: Icons.workspace_premium_rounded,
                  color: AppTheme.goldDeep,
                  kind: 'info',
                  title: 'Premium ends in $days day${days == 1 ? '' : 's'}',
                  subtitle: 'Renew for 0% commission',
                  time: '',
                  route: '/driver/subscription'));
            }
          } catch (_) {}
        }
      }

      if (results[3].statusCode == 200) {
        final w = jsonDecode(results[3].body) as Map<String, dynamic>;
        for (final e in ((w["transactions"] as List?) ?? []).take(4)) {
          final t = Map<String, dynamic>.from(e as Map);
          final desc = t["description"]?.toString() ?? '';
          if (t["type"]?.toString() == 'debit' && desc.contains('ayout')) {
            items.add(_NItem(
                icon: Icons.account_balance_rounded,
                color: AppTheme.primary,
                kind: 'payout',
                title: 'Payout ₹${t["amount"]}',
                subtitle: desc,
                time: _ago(t["createdAt"]?.toString()),
                route: '/driver/wallet'));
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<_NItem> get _shown =>
      _tab == 'all' ? _items : _items.where((e) => e.kind == _tab).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _header(context),
          _tabs(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navy, AppTheme.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text('Notifications',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              const Icon(Icons.notifications_outlined,
                  color: Colors.white70, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    const tabs = [
      ('all', 'All'),
      ('bid', 'Bids'),
      ('payout', 'Payouts'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: tabs.map((t) {
          final sel = _tab == t.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _tab = t.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.goldGradient : null,
                  color: sel ? null : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Text(t.$2,
                    style: TextStyle(
                        color: sel ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    final list = _shown;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSm,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            const Text('Nothing here yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Go online — requests will appear here.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = list[i];
          return GestureDetector(
            onTap: n.route == null ? null : () => Nav.push(context, n.route!),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(n.icon, color: n.color, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary)),
                            ),
                            if (n.time.isNotEmpty)
                              Text(n.time,
                                  style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(n.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12.5)),
                      ],
                    ),
                  ),
                  if (n.route != null)
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textTertiary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
