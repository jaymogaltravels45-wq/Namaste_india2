import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/widgets/neumorphic.dart";

/// P27 — Notifications (driver). Bookings, bids aur subscription se banti hain.
class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});
  @override
  State<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _Item {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String? route;
  _Item(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.time,
      this.route});
}

class _DriverNotificationsScreenState
    extends State<DriverNotificationsScreen> {
  bool _loading = true;
  List<_Item> _items = [];

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
      if (d.inMinutes < 1) return 'abhi';
      if (d.inMinutes < 60) return '${d.inMinutes} min pehle';
      if (d.inHours < 24) return '${d.inHours} ghante pehle';
      return '${d.inDays} din pehle';
    } catch (_) {
      return '';
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = <_Item>[];
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

      // Nayi booking requests
      if (results[0].statusCode == 200) {
        final a = jsonDecode(results[0].body) as Map<String, dynamic>;
        final raw = (a["bookings"] as List?) ?? [];
        for (final e in raw.take(5)) {
          final b = Map<String, dynamic>.from(e as Map);
          final from =
              (b["pickup"] is Map ? b["pickup"]["address"] : '') ?? '';
          final to = (b["drop"] is Map ? b["drop"]["address"] : '') ?? '';
          final fare = b["estimatedFare"] ?? b["finalFare"] ?? '';
          items.add(_Item(
            icon: Icons.gavel_rounded,
            color: NeuColors.accent,
            title: 'Nayi bid request paas me',
            subtitle: '$from → $to • ₹$fare',
            time: _ago((b["createdAt"])?.toString()),
            route: '/driver',
          ));
        }
      }

      // Meri bookings ki halchal
      if (results[1].statusCode == 200) {
        final m = jsonDecode(results[1].body) as Map<String, dynamic>;
        final raw = (m["bookings"] as List?) ?? [];
        for (final e in raw.take(5)) {
          final b = Map<String, dynamic>.from(e as Map);
          final status = b["status"]?.toString() ?? '';
          final id = b["_id"]?.toString();
          final ts = (b["updatedAt"] ?? b["createdAt"])?.toString();
          if (status == 'driver_assigned') {
            items.add(_Item(
              icon: Icons.check_circle_rounded,
              color: NeuColors.success,
              title: 'Booking tumhari hui',
              subtitle: 'Customer tak pahuncho aur "Arrived" dabao',
              time: _ago(ts),
              route: id == null ? null : '/driver/my-booking/$id',
            ));
          } else if (status == 'completed') {
            final fare = b["finalFare"] ?? b["estimatedFare"] ?? '';
            items.add(_Item(
              icon: Icons.payments_rounded,
              color: NeuColors.success,
              title: 'Trip poori — payment aaya',
              subtitle: '₹$fare wallet me jod diya gaya',
              time: _ago(ts),
              route: '/driver/earnings',
            ));
          }
        }
      }

      // Subscription khatam hone wala
      if (results[2].statusCode == 200) {
        final s = jsonDecode(results[2].body) as Map<String, dynamic>;
        if (s["active"] == true && s["endsAt"] != null) {
          try {
            final ends =
                DateTime.parse(s["endsAt"].toString()).toLocal();
            final days = ends.difference(DateTime.now()).inDays;
            if (days <= 3) {
              items.add(_Item(
                icon: Icons.workspace_premium_rounded,
                color: NeuColors.accent,
                title: 'Premium $days din me khatam',
                subtitle: '0% commission jaari rakhne ke liye renew karo',
                time: '',
                route: '/driver/subscription',
              ));
            }
          } catch (_) {}
        }
      }

      // Wallet transactions — payout
      if (results[3].statusCode == 200) {
        final w = jsonDecode(results[3].body) as Map<String, dynamic>;
        final txs = (w["transactions"] as List?) ?? [];
        for (final e in txs.take(3)) {
          final t = Map<String, dynamic>.from(e as Map);
          if (t["type"]?.toString() == 'debit' &&
              (t["description"]?.toString() ?? '').contains('ayout')) {
            items.add(_Item(
              icon: Icons.account_balance_rounded,
              color: NeuColors.textDark,
              title: '₹${t["amount"]} ka payout hua',
              subtitle: t["description"]?.toString() ?? '',
              time: _ago(t["createdAt"]?.toString()),
              route: '/driver/wallet',
            ));
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeuHeader(
                title: 'Notifications',
                subtitle: 'Kamayi se judi taaza khabar',
              ),
              const SizedBox(height: 18),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: NeuColors.card,
                shape: BoxShape.circle,
                boxShadow: NeuShadows.raised(),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: NeuColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text('Abhi koi notification nahi',
                style: TextStyle(
                    color: NeuColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Online jao — nayi requests yahin aayengi.',
                style: TextStyle(color: NeuColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final n = _items[i];
          return NeuCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            onTap:
                n.route == null ? null : () => context.go(n.route!),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title,
                          style: const TextStyle(
                              color: NeuColors.textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(n.subtitle,
                          style: const TextStyle(
                              color: NeuColors.textMuted, fontSize: 12.5)),
                      if (n.time.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(n.time,
                            style: const TextStyle(
                                color: NeuColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                if (n.route != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: NeuColors.textMuted),
              ],
            ),
          );
        },
      ),
    );
  }
}
