import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../core/routes/nav.dart';

class CustomerBookingHistoryScreen extends StatefulWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  State<CustomerBookingHistoryScreen> createState() =>
      _CustomerBookingHistoryScreenState();
}

class _CustomerBookingHistoryScreenState
    extends State<CustomerBookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String? _error;

  static const _tabs = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer \$token',
    };
  }

  Future<void> _fetchBookings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('\${AppConfig.apiBaseUrl}/bookings/customer'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        final list = body['bookings'] as List? ?? [];
        setState(() {
          _all = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = body['message']?.toString() ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Network error. Pull down to retry.'; _loading = false; });
    }
  }

  List<Map<String, dynamic>> _filtered(int idx) {
    if (idx == 0) return _all;
    final filter = ['', 'started,ongoing,driver_assigned,arrived,open_for_bids', 'completed', 'cancelled'][idx].split(',');
    return _all.where((b) => filter.contains(b['status']?.toString() ?? '')).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildHeader()],
        body: _loading
            ? _buildSkeleton()
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tab,
                    children: List.generate(
                        _tabs.length, (i) => _buildList(_filtered(i))),
                  ),
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryDeep,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: Stack(
            children: [
              Positioned(right: -30, top: -30,
                  child: _blob(140, Colors.white.withOpacity(0.07))),
              Positioned(left: -20, bottom: -40,
                  child: _blob(110, AppTheme.gold.withOpacity(0.10))),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text('My Trips',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                          const Spacer(),
                          if (_all.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('\${_all.length} trips',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppTheme.primaryDeep,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            indicator: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 18),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonTripCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppTheme.error, size: 40),
          ),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          PremiumButton(
            label: 'Retry',
            onPressed: _fetchBookings,
            icon: Icons.refresh_rounded,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return PremiumEmpty(
        icon: Icons.directions_car_outlined,
        title: 'No trips found',
        subtitle: 'Your booking history will appear here once you take a ride.',
        ctaLabel: 'Book a Ride',
        onCta: () => Nav.go(context, '/customer/booking'),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchBookings,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            Entrance(delayMs: i * 40, child: _TripCard(booking: items[i])),
      ),
    );
  }

  Widget _blob(double s, Color c) =>
      Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

// ───────────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _TripCard({required this.booking});

  String get _id => (booking['id']?.toString() ?? '').length > 6
      ? '#\${booking["id"].toString().substring(0, 6).toUpperCase()}'
      : '#\${booking["id"] ?? "--"}';

  String get _pickup => booking['pickup_location']?.toString() ?? 'N/A';
  String get _drop => booking['drop_location']?.toString() ?? 'N/A';
  String get _status => booking['status']?.toString() ?? 'pending';
  String get _type => booking['trip_type']?.toString() ?? 'outstation';
  String get _vehicle => booking['vehicle_type']?.toString() ?? 'sedan';
  String get _date {
    final d = booking['pickup_time']?.toString() ?? booking['created_at']?.toString() ?? '';
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '\${dt.day} \${months[dt.month - 1]}, \${dt.hour}:\${dt.minute.toString().padLeft(2, "0")}';
    } catch (_) { return d.length > 10 ? d.substring(0, 10) : d; }
  }
  String get _fare {
    final f = booking['final_fare'] ?? booking['estimated_fare'];
    if (f == null) return '';
    return '\u20B9\${double.tryParse(f.toString())?.toStringAsFixed(0) ?? f}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Nav.push(context, '/customer/booking/\${booking["id"]}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          border: Border.all(color: AppTheme.border.withOpacity(0.6)),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          children: [
            // ── Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Text(_id,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: AppTheme.textTertiary)),
                  const SizedBox(width: 8),
                  _typePill(),
                  const Spacer(),
                  StatusBadge.fromStatus(_status),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),
            // ── Route
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  _routeRow(Icons.radio_button_checked_rounded,
                      AppTheme.primary, 'PICKUP', _pickup),
                  // vertical line
                  Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary.withOpacity(0.3),
                                AppTheme.error.withOpacity(0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _routeRow(Icons.location_on_rounded,
                      AppTheme.error, 'DROP', _drop),
                ],
              ),
            ),
            // ── Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 13, color: AppTheme.textTertiary),
                  const SizedBox(width: 5),
                  Text(_vehicle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textTertiary)),
                  if (_date.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded,
                        size: 13, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(_date,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textTertiary)),
                  ],
                  const Spacer(),
                  if (_fare.isNotEmpty)
                    Text(_fare,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppTheme.textTertiary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typePill() {
    final labels = {
      'outstation': 'One Way',
      'round': 'Round Trip',
      'local': 'Local',
      'bid': 'Bid',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(labels[_type] ?? _type,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
    );
  }
}
