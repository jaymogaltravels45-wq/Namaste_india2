import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth/auth_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _phone = '';
  bool _loading = true;
  bool _saving = false;
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

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
    ));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/customers/profile'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        final user = body['user'] as Map<String, dynamic>? ?? {};
        setState(() {
          _nameCtrl.text = user['name']?.toString() ?? '';
          _emailCtrl.text = user['email']?.toString() ?? '';
          _phone = user['phone']?.toString() ??
              AuthService.phone ??
              '';
        });
      } else {
        setState(() {
          _error = body['message']?.toString() ?? 'Could not load';
          _phone = AuthService.phone ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error: $e';
          _phone = AuthService.phone ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Name likhiye', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/customers/profile'),
        headers: _headers(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        _snack('Profile save ho gaya!');
      } else {
        _snack(body['message']?.toString() ?? 'Save nahi ho paya',
            error: true);
      }
    } catch (e) {
      _snack('Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout karein?'),
        content: const Text('Kya tum logout karna chahte ho?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ruko')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthService.signOut();
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Meri Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _avatarCard(),
                  const SizedBox(height: 16),
                  _field('Name', _nameCtrl, Icons.person, 'Apna naam likhiye'),
                  const SizedBox(height: 12),
                  _field('Email', _emailCtrl, Icons.email,
                      'email@example.com',
                      email: true),
                  const SizedBox(height: 12),
                  _phoneField(),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Save Karo',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _avatarCard() {
    final initial =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'N';
    return Container(
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameCtrl.text.isEmpty ? 'Namaste!' : _nameCtrl.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_phone,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      String hint,
      {bool email = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              email ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _phoneField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone number',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: _phone),
            readOnly: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
              suffixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 4),
          Text('Phone number change nahi ho sakta',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      );

  Widget _bottomNav(BuildContext ctx) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        currentIndex: 3,
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
