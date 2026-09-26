import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/nav.dart';

class CustomerBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const CustomerBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<CustomerBookingDetailScreen> createState() =>
      _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState
    extends State<CustomerBookingDetailScreen> {
  Map<String, dynamic>? _booking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _booking = body['booking'] as Map<String, dynamic>);
      } else {
        setState(
            () => _error = body['message']?.toString() ?? 'Could not load');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Looking for a driver';
      case 'driver_assigned':
        return 'Driver assigned';
      case 'started':
        return 'Ride in progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _detailView(),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_error ?? 'Something went wrong',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _load, child: const Text('Try Again')),
            ],
          ),
        ),
      );

  Widget _detailView() {
    final b = _booking!;
    final status = b['status']?.toString() ?? 'pending';
    final paymentStatus = b['paymentStatus']?.toString() ?? 'pending';
    final driverRaw = b['driverId'];
    final Map<String, dynamic>? driver =
        driverRaw is Map<String, dynamic> ? driverRaw : null;
    final fare = b['finalFare'] ?? b['estimatedFare'];
    final type = b['bookingType']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusCard(status),
          const SizedBox(height: 16),
          _card('Trip', [
            _row(Icons.my_location, 'Pickup',
                b['pickup']?['address']?.toString() ?? '-'),
            _row(Icons.location_on, 'Drop',
                b['drop']?['address']?.toString() ?? '-'),
            _row(Icons.calendar_today, 'Pickup time',
                b['pickupTimeIST']?.toString() ?? '-'),
            if ((b['distanceKm'] ?? 0) != 0)
              _row(Icons.straighten, 'Distance', '${b['distanceKm']} km'),
            if (b['localPackage'] != null)
              _row(Icons.timer, 'Package', b['localPackage'].toString()),
          ]),
          const SizedBox(height: 12),
          _card('Vehicle & Fare', [
            _row(Icons.directions_car, 'Vehicle',
                _vehicleLabel(b['vehicleType']?.toString() ?? '')),
            _row(Icons.confirmation_number, 'Booking type',
                _typeLabel(type)),
            _row(Icons.currency_rupee, 'Fare',
                fare != null ? '₹$fare' : 'Driver will confirm'),
            _row(Icons.payment, 'Payment', _paymentLabel(paymentStatus)),
          ]),
          if (driver != null) ...[
            const SizedBox(height: 12),
            _card('Driver', [
              _row(Icons.person, 'Name',
                  driver['name']?.toString() ?? 'Driver'),
              if (driver['phone'] != null)
                _row(Icons.phone, 'Phone', driver['phone'].toString()),
              if (driver['vehicleNumber'] != null)
                _row(Icons.directions_car, 'Vehicle number',
                    driver['vehicleNumber'].toString()),
            ]),
          ],
          if (status == 'open_for_bids') ...[
            const SizedBox(height: 12),
            _CustomerBidsSection(
                bookingId: widget.bookingId, onAccepted: _load),
          ],
          if ((b['rideOtp'] ?? b['otp']) != null && status == 'arrived') ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Nav.push(context, '/ride-otp/${widget.bookingId}'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.key, color: AppTheme.warning),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text('View Ride OTP — share with your driver',
                            style:
                                TextStyle(fontWeight: FontWeight.w600))),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (paymentStatus == 'pending' && status != 'cancelled')
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () =>
                    Nav.push(context, '/payment/${widget.bookingId}'),
                child: const Text('Pay Now',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          if (status == 'completed') ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Nav.push(context, '/rating/${widget.bookingId}'),
                icon: const Icon(Icons.star),
                label: const Text('Rate this ride'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusCard(String status) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long,
                color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking ${(_booking!['bookingNumber'] ?? '').toString()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _card(String title, List<Widget> rows) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      );

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );

  String _vehicleLabel(String v) {
    switch (v) {
      case 'hatchback':
        return 'Hatchback';
      case 'suv':
        return 'SUV';
      case 'innova':
        return 'Innova';
      default:
        return 'Sedan';
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'outstation':
        return 'One Way';
      case 'round_trip':
        return 'Round Trip';
      case 'local':
        return 'Local';
      case 'bid':
        return 'Bid';
      default:
        return t;
    }
  }

  String _paymentLabel(String p) {
    switch (p) {
      case 'cash':
        return 'Cash — Paid';
      case 'upi':
        return 'UPI — Paid';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Pending';
    }
  }
}

/// Driver bids on a customer's bid-booking, with accept option.
class _CustomerBidsSection extends StatefulWidget {
  final String bookingId;
  final VoidCallback onAccepted;
  const _CustomerBidsSection(
      {required this.bookingId, required this.onAccepted});

  @override
  State<_CustomerBidsSection> createState() => _CustomerBidsSectionState();
}

class _CustomerBidsSectionState extends State<_CustomerBidsSection> {
  List<dynamic> _bids = [];
  bool _loading = true;
  String? _acceptingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}/bids'),
        headers: _headers(),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _bids = (body['bids'] as List?)?.where((b) =>
              (b['status'] ?? 'pending') == 'pending').toList() ?? [];
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String bidId) async {
    setState(() => _acceptingId = bidId);
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/bids/$bidId/accept'),
        headers: _headers(),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Driver confirmed! 🎉'),
          backgroundColor: AppTheme.success,
        ));
        widget.onAccepted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text((body['message'] ?? 'Could not accept').toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Network error'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.gavel, color: Color(0xFF6A1B9A)),
              SizedBox(width: 8),
              Text('Driver Bids',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            const Text('Choose the best offer — lowest price is not auto-selected',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_bids.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text('No bids yet — check back shortly',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13))),
              )
            else
              ..._bids.map((b) => _bidTile(b)),
          ],
        ),
      );

  Widget _bidTile(dynamic b) {
    final m = Map<String, dynamic>.from(b as Map);
    final d = m['driver'];
    final dm = d is Map ? Map<String, dynamic>.from(d) : null;
    final id = m['_id'].toString();
    final accepting = _acceptingId == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF6A1B9A),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dm?['name']?.toString() ?? 'Driver',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      '${dm?['vehicleNumber']?.toString() ?? ''} · ${dm?['experience']?.toString() ?? ''} exp · ★${dm?['rating']?.toString() ?? '-'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  if ((m['message'] ?? '').toString().isNotEmpty)
                    Text(m['message'].toString(),
                        style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Text('₹${m['amount']}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6A1B9A))),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: accepting ? null : () => _accept(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              child: accepting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Select This Driver'),
            ),
          ),
        ],
      ),
    );
  }
}
