import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  const RatingScreen({super.key, required this.bookingId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _reviewCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  static const _labels = {
    1: 'Bahut kharab',
    2: 'Kharab',
    3: 'Theek thaak',
    4: 'Achha',
    5: 'Bahut badhiya!',
  };

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

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await http.patch(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}/rating'),
        headers: _headers(),
        body: jsonEncode({
          'rating': _rating,
          'review': _reviewCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        _snack('Shukriya! Tumhari rating save ho gayi.');
        context.go('/customer');
      } else {
        _snack(body['message']?.toString() ?? 'Rating save nahi hui',
            error: true);
      }
    } catch (e) {
      _snack('Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _skip() => context.go('/customer');

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ride Rating'),
        actions: [
          TextButton(onPressed: _skip, child: const Text('Skip')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 56),
            ),
            const SizedBox(height: 20),
            const Text('Ride kaisi rahi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Driver ko rating do',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  iconSize: 44,
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade600,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(_labels[_rating]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const Text('Review likho (optional)',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _reviewCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Driver ke baare me kuch achha likho...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Rating Bhejo',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _skip,
              child: const Text('Abhi nahi, baad me'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
