import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

class RideOtpScreen extends StatefulWidget {
  final String bookingId;
  const RideOtpScreen({super.key, required this.bookingId});

  @override
  State<RideOtpScreen> createState() => _RideOtpScreenState();
}

class _RideOtpScreenState extends State<RideOtpScreen> {
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
            () => _error = body['message']?.toString() ?? 'Load nahi ho paya');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyOtp(String otp) {
    Clipboard.setData(ClipboardData(text: otp));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('OTP copy ho gaya'),
      backgroundColor: AppTheme.success,
    ));
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
        return 'Driver dhoondh rahe hain';
      case 'driver_assigned':
        return 'Driver mil gaya — OTP batao';
      case 'started':
        return 'Ride chal rahi hai';
      case 'completed':
        return 'Ride poori ho gayi';
      case 'cancelled':
        return 'Cancel ho gayi';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ride OTP'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _otpView(),
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

  Widget _otpView() {
    final b = _booking!;
    final otp = b['otp']?.toString() ?? '------';
    final status = b['status']?.toString() ?? 'pending';
    final driverRaw = b['driverId'];
    final Map<String, dynamic>? driver =
        driverRaw is Map<String, dynamic> ? driverRaw : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _statusColor(status),
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.key, size: 48, color: AppTheme.warning),
          const SizedBox(height: 12),
          const Text('Driver ko ye OTP batayein',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _copyOtp(otp),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 26),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.warning.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    otp,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('Tap karke copy karo',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: const Text(
              'Ride shuru karne se pehle driver tumse ye OTP maangega. Sahi OTP pe hi ride start hogi — ye tumhari safety ke liye hai.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          if (driver != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tumhara Driver',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  _driverRow(Icons.person, 'Naam',
                      driver['name']?.toString() ?? 'Driver'),
                  if (driver['vehicleNumber'] != null)
                    _driverRow(Icons.directions_car, 'Gaadi number',
                        driver['vehicleNumber'].toString()),
                  if (driver['phone'] != null)
                    _driverRow(Icons.phone, 'Phone',
                        driver['phone'].toString()),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.go('/customer/booking/${widget.bookingId}'),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Booking Details Dekho'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _driverRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
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
}
