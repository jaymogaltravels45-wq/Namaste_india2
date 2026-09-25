import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/widgets/neumorphic.dart";

/// P14 — Notifications (customer). Bookings se asli notifications banti hain.
class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _Item {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String? bookingId;
  _Item(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.time,
      this.bookingId});
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
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
      final res = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/customer/my"),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (body["bookings"] as List?) ?? [];
        for (final e in raw) {
          final b = Map<String, dynamic>.from(e as Map);
          final status = b["status"]?.toString() ?? '';
          final id = b["_id"]?.toString();
          final from = (b["pickup"] is Map ? b["pickup"]["address"] : '') ?? '';
          final to = (b["drop"] is Map ? b["drop"]["address"] : '') ?? '';
          final route = '$from → $to';
          final ts = (b["updatedAt"] ?? b["createdAt"])?.toString();
          switch (status) {
            case 'driver_assigned':
              items.add(_Item(
                icon: Icons.drive_eta_rounded,
                color: NeuColors.success,
                title: 'Driver mil gaya!',
                subtitle: '$route — driver aa raha hai',
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'arrived':
              items.add(_Item(
                icon: Icons.location_on_rounded,
                color: NeuColors.accent,
                title: 'Driver pahunch gaya',
                subtitle: '$route — ride OTP driver ko batao',
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'ongoing':
            case 'started':
              items.add(_Item(
                icon: Icons.navigation_rounded,
                color: NeuColors.accent,
                title: 'Trip chal rahi hai',
                subtitle: route,
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'open_for_bids':
              items.add(_Item(
                icon: Icons.gavel_rounded,
                color: NeuColors.accent,
                title: 'Nayi driver offers aayi hain',
                subtitle: '$route — compare karke chuno',
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'completed':
              items.add(_Item(
                icon: Icons.star_rounded,
                color: NeuColors.accent,
                title: 'Trip poori hui',
                subtitle: '$route — rating dena na bhoolo',
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'pending':
              items.add(_Item(
                icon: Icons.hourglass_empty_rounded,
                color: NeuColors.textMuted,
                title: 'Driver ka intezaar',
                subtitle: '$route — jaldi driver milega',
                time: _ago(ts),
                bookingId: id,
              ));
              break;
            case 'cancelled':
              items.add(_Item(
                icon: Icons.cancel_rounded,
                color: NeuColors.error,
                title: 'Booking cancel hui',
                subtitle: route,
                time: _ago(ts),
                bookingId: null,
              ));
              break;
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
                subtitle: 'Tumhari trips ki taaza khabar',
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
            const Text('Booking karoge to yahin khabar aayegi.',
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
            onTap: n.bookingId == null
                ? null
                : () => context.go('/customer/booking/${n.bookingId}'),
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
                if (n.bookingId != null)
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
