import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/nav.dart';

class CustomerTripTrackingScreen extends StatefulWidget {
  final String bookingId;
  const CustomerTripTrackingScreen({super.key, required this.bookingId});
  @override
  State<CustomerTripTrackingScreen> createState() =>
      _CustomerTripTrackingScreenState();
}

class _CustomerTripTrackingScreenState
    extends State<CustomerTripTrackingScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}'),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _booking = body['booking'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    final status = b?['status']?.toString() ?? 'searching';
    final driver = b?['driver'] as Map?;
    final otp = b?['rideStartOtp']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Trip Tracking'),
        backgroundColor: AppTheme.primaryDeep,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Status card ─────────────────────────────
                  _statusCard(status),
                  const SizedBox(height: 14),

                  // ── Map placeholder ──────────────────────────
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0A2A5E)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded,
                              size: 48, color: Colors.white54),
                          SizedBox(height: 8),
                          Text('Live Map',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          Text('(Coming soon with Google Maps API)',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Driver card ──────────────────────────────
                  if (driver != null) _driverCard(driver),
                  if (driver != null) const SizedBox(height: 14),

                  // ── OTP card ─────────────────────────────────
                  if (otp != null) _otpCard(otp),
                  if (otp != null) const SizedBox(height: 14),

                  // ── Trip timeline ────────────────────────────
                  _timelineCard(status),
                  const SizedBox(height: 14),

                  // ── Action buttons ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          Icons.call_rounded,
                          'Call Driver',
                          AppTheme.success,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          Icons.share_rounded,
                          'Share Trip',
                          AppTheme.primary,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          Icons.emergency_rounded,
                          'SOS',
                          AppTheme.error,
                          () => Nav.push(context, '/customer/sos'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _statusCard(String status) {
    final statusMap = {
      'searching': ('Searching for driver...', AppTheme.warning, Icons.search_rounded),
      'accepted': ('Driver found! Coming to pickup', AppTheme.info, Icons.directions_car_rounded),
      'arrived': ('Driver arrived at pickup', AppTheme.success, Icons.location_on_rounded),
      'in_progress': ('Trip in progress', AppTheme.primary, Icons.directions_car_filled_rounded),
      'completed': ('Trip completed!', AppTheme.success, Icons.check_circle_rounded),
      'cancelled': ('Trip cancelled', AppTheme.error, Icons.cancel_rounded),
    };
    final s = statusMap[status] ?? ('Status: $status', AppTheme.textSecondary, Icons.info_rounded);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: s.$2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: s.$2.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.$2.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(s.$3, color: s.$2, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(s.$1,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: s.$2)),
          ),
        ],
      ),
    );
  }

  Widget _driverCard(Map driver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver['name']?.toString() ?? 'Driver',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(
                  '${driver['vehicleModel'] ?? ''} • ${driver['vehicleNumber'] ?? ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppTheme.goldDeep),
                    Text(' ${driver['rating'] ?? '4.5'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.success.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    size: 14, color: AppTheme.success),
                SizedBox(width: 4),
                Text('Verified',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpCard(String otp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowBlue,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ride Start OTP',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(otp,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8)),
              ],
            ),
          ),
          const Column(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.white60, size: 16),
              SizedBox(height: 4),
              Text('Share with',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 10)),
              Text('driver only',
                  style:
                      TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(String status) {
    final steps = [
      ('Booking Confirmed', true),
      ('Driver Assigned', [' accepted', 'arrived', 'in_progress', 'completed'].contains(status)),
      ('Driver Arrived', ['arrived', 'in_progress', 'completed'].contains(status)),
      ('Trip Started', ['in_progress', 'completed'].contains(status)),
      ('Trip Completed', status == 'completed'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Timeline',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          ...steps.map((s) => _timelineStep(s.$1, s.$2)),
        ],
      ),
    );
  }

  Widget _timelineStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppTheme.success : AppTheme.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight:
                      done ? FontWeight.w700 : FontWeight.w400,
                  color: done
                      ? AppTheme.textPrimary
                      : AppTheme.textTertiary,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
