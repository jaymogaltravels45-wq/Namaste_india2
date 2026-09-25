import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth/auth_service.dart';
import '../admin_api.dart';

/// App settings: company UPI info, feature toggles, logout.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  String? _upiId;
  String? _companyName;
  bool _loadingUpi = true;

  bool _bookingsEnabled = true;
  bool _newDriverSignup = true;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _loadUpi();
  }

  Future<void> _loadUpi() async {
    try {
      final res = await AdminApi.get('/api/payments/upi-info');
      if (!mounted) return;
      setState(() {
        _upiId = res['upiId']?.toString();
        _companyName = res['companyName']?.toString();
        _loadingUpi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _upiId = 'namasteindia@upi';
        _companyName = 'Namaste India';
        _loadingUpi = false;
      });
    }
  }

  Future<void> _copyUpi() async {
    if (_upiId == null) return;
    await Clipboard.setData(ClipboardData(text: _upiId!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('UPI ID copy ho gaya.'),
          backgroundColor: AppTheme.success),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout?'),
        content:
            const Text('Kya aap admin panel se logout karna chahte hain?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.signOut();
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UPI card
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
                const Row(
                  children: [
                    Icon(Icons.qr_code_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Company UPI',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loadingUpi)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: AppTheme.primary),
                  ))
                else ...[
                  Text(_companyName ?? 'Namaste India',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_upiId ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppTheme.primary),
                        onPressed: _copyUpi,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Customers isi UPI ID par payment karte hain.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Toggles
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _toggle(
                  'Bookings enabled',
                  'Band karne par nayi booking nahi hogi',
                  _bookingsEnabled,
                  (v) => setState(() => _bookingsEnabled = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _toggle(
                  'Driver signup',
                  'Naye drivers register kar sakte hain',
                  _newDriverSignup,
                  (v) => setState(() => _newDriverSignup = v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _toggle(
                  'Maintenance mode',
                  'App me "jald wapas aayenge" dikhega',
                  _maintenanceMode,
                  (v) {
                    setState(() => _maintenanceMode = v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(v
                            ? 'Maintenance mode ON'
                            : 'Maintenance mode OFF'),
                        backgroundColor:
                            v ? AppTheme.warning : AppTheme.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _infoRow('App', AppConfig.appName),
                _infoRow('Package', AppConfig.packageName),
                _infoRow('Version', '1.0.0+1'),
                _infoRow('Backend', AppConfig.apiBaseUrl),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _logout,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _toggle(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(sub,
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
      value: value,
      activeColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _infoRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style:
                        const TextStyle(color: AppTheme.textSecondary))),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
}
