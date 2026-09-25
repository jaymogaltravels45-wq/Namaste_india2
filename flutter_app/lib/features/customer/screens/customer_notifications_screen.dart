import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

/// P14 (Travel edition) — Notifications. Built from the customer's bookings.
class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _NItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String? bookingId;
  _NItem(
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
  List<_NItem> _items = [];

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
              items.add(_NItem(
                  icon: Icons.drive_eta_rounded,
                  color: AppTheme.success,
                  title: 'Driver assigned',
                  subtitle: route,
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'arrived':
              items.add(_NItem(
                  icon: Icons.location_on_rounded,
                  color: AppTheme.goldDeep,
                  title: 'Driver arrived',
                  subtitle: 'Share the ride OTP to start',
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'ongoing':
            case 'started':
              items.add(_NItem(
                  icon: Icons.navigation_rounded,
                  color: AppTheme.primary,
                  title: 'Trip in progress',
                  subtitle: route,
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'open_for_bids':
              items.add(_NItem(
                  icon: Icons.gavel_rounded,
                  color: AppTheme.goldDeep,
                  title: 'New driver offers',
                  subtitle: route,
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'completed':
              items.add(_NItem(
                  icon: Icons.star_rounded,
                  color: AppTheme.goldDeep,
                  title: 'Trip completed',
                  subtitle: 'Rate your ride',
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'pending':
              items.add(_NItem(
                  icon: Icons.hourglass_empty_rounded,
                  color: AppTheme.textSecondary,
                  title: 'Finding your driver',
                  subtitle: route,
                  time: _ago(ts),
                  bookingId: id));
              break;
            case 'cancelled':
              items.add(_NItem(
                  icon: Icons.cancel_outlined,
                  color: AppTheme.error,
                  title: 'Booking cancelled',
                  subtitle: route,
                  time: _ago(ts)));
              break;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _header(context),
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
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSm,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            const Text('No notifications yet',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Trip updates will appear here.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _items[i];
          return GestureDetector(
            onTap: n.bookingId == null
                ? null
                : () => context.go('/customer/booking/${n.bookingId}'),
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
                  if (n.bookingId != null)
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
