import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/nav.dart';

class CustomerBookingHistoryScreen extends StatefulWidget {
  const CustomerBookingHistoryScreen({super.key});

  @override
  State<CustomerBookingHistoryScreen> createState() =>
      _CustomerBookingHistoryScreenState();
}

class _CustomerBookingHistoryScreenState
    extends State<CustomerBookingHistoryScreen> {
  List<dynamic> _bookings = [];
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
        Uri.parse('${AppConfig.apiBaseUrl}/bookings/customer/my'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _bookings = body['bookings'] as List<dynamic>);
      } else {
        setState(
            () => _error = body['message']?.toString() ?? 'Load nahi ho paya');
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
        return 'Pending';
      case 'driver_assigned':
        return 'Driver mil gaya';
      case 'started':
        return 'Chal rahi hai';
      case 'completed':
        return 'Poori';
      case 'cancelled':
        return 'Cancel';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meri Trips'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _bookings.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (ctx, i) =>
                            _bookingTile(_bookings[i] as Map<String, dynamic>),
                      ),
                    ),
      bottomNavigationBar: _bottomNav(context),
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
              Text(_error ?? 'Kuch gadbad ho gayi',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _load, child: const Text('Dobara try karo')),
            ],
          ),
        ),
      );

  Widget _emptyView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history,
                    size: 48, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              const Text('Abhi koi trip nahi hai',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Pehli ride book karo!',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Nav.push(context, '/customer/booking'),
                child: const Text('Book a Ride'),
              ),
            ],
          ),
        ),
      );

  Widget _bookingTile(Map<String, dynamic> b) {
    final id = b['_id']?.toString() ?? '';
    final status = b['status']?.toString() ?? 'pending';
    final pickup = b['pickup']?['address']?.toString() ?? '-';
    final drop = b['drop']?['address']?.toString() ?? '-';
    final fare = b['finalFare'] ?? b['estimatedFare'];
    final created = b['createdAt']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => Nav.push(context, '/customer/booking/$id'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (b['bookingNumber'] ?? 'Booking').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _routeLine(Icons.my_location, pickup, AppTheme.success),
              _routeLine(Icons.location_on, drop, AppTheme.error),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    created.length >= 10
                        ? created.substring(0, 10)
                        : created,
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  if (fare != null)
                    Text('₹$fare',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeLine(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _bottomNav(BuildContext ctx) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        currentIndex: 2,
        onTap: (i) {
          const routes = [
            '/customer',
            '/customer/booking',
            '/customer/history',
            '/customer/profile'
          ];
          if (i < routes.length) ctx.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Book'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      );
}
