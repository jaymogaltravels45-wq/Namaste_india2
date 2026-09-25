import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _txnCtrl = TextEditingController();
  String _method = 'cash';
  String? _upiId;
  String? _companyName;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpiInfo();
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
    ));
  }

  Future<void> _loadUpiInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/payments/upi-info'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() {
          _upiId = body['upiId']?.toString();
          _companyName = body['companyName']?.toString() ?? 'Namaste India';
        });
      } else {
        setState(() => _error = 'UPI info nahi mil payi');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    if (_method == 'upi' && _txnCtrl.text.trim().isEmpty) {
      _snack('UPI transaction ID likhiye (optional nahi, zaroori hai)',
          error: true);
      return;
    }
    setState(() => _paying = true);
    try {
      final payload = <String, dynamic>{'method': _method};
      if (_method == 'upi') {
        payload['upiTransactionId'] = _txnCtrl.text.trim();
      }
      final res = await http.post(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/payments/${widget.bookingId}/pay'),
        headers: _headers(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        _snack('Payment ho gaya! Shukriya.');
        context.go('/rating/${widget.bookingId}');
      } else {
        _snack(body['message']?.toString() ?? 'Payment fail ho gaya',
            error: true);
      }
    } catch (e) {
      _snack('Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _copyUpi() {
    if (_upiId == null) return;
    Clipboard.setData(ClipboardData(text: _upiId!));
    _snack('UPI ID copy ho gaya: $_upiId');
  }

  @override
  void dispose() {
    _txnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Payment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _headerCard(),
                      const SizedBox(height: 16),
                      _methodTile(
                        'cash',
                        'Cash',
                        'Driver ko ride ke baad de do',
                        Icons.money,
                        AppTheme.success,
                      ),
                      const SizedBox(height: 10),
                      _methodTile(
                        'upi',
                        'UPI',
                        'Company ke UPI ID pe pay karo',
                        Icons.qr_code,
                        AppTheme.primary,
                      ),
                      if (_method == 'upi') ...[
                        const SizedBox(height: 16),
                        _upiCard(),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _paying ? null : _pay,
                          child: _paying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Text(
                                  _method == 'cash'
                                      ? 'Cash se Pay Karo'
                                      : 'UPI Payment Confirm Karo',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
                  onPressed: _loadUpiInfo,
                  child: const Text('Dobara try karo')),
            ],
          ),
        ),
      );

  Widget _headerCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.payment, color: Colors.white, size: 32),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ride ka payment',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Cash ya UPI — jo convenient lage',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _methodTile(String value, String title, String subtitle,
      IconData icon, Color color) {
    final selected = _method == value;
    return InkWell(
      onTap: () => setState(() => _method = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _method,
              activeColor: color,
              onChanged: (v) => setState(() => _method = v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upiCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company UPI ID',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _copyUpi,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_upiId ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5)),
                    ),
                    const Icon(Icons.copy,
                        color: AppTheme.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Apne UPI app (GPay/PhonePe/Paytm) me ye ID daal ke payment karo\n2. Neeche transaction ID likho\n3. Confirm dabao',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text('UPI Transaction ID',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _txnCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 412345678901',
                prefixIcon:
                    Icon(Icons.receipt_long, color: AppTheme.primary),
              ),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      );
}
