import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/routes/nav.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _notifications = true;
  bool _rideUpdates = true;
  String _language = 'Hinglish';
  bool _loading = true;

  static const _prefsKeys = {
    'notifications': 'pref_notifications',
    'rideUpdates': 'pref_ride_updates',
    'language': 'pref_language',
  };

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool(_prefsKeys['notifications']!) ?? true;
      _rideUpdates = prefs.getBool(_prefsKeys['rideUpdates']!) ?? true;
      _language = prefs.getString(_prefsKeys['language']!) ?? 'Hinglish';
      _loading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveLanguage(String value) async {
    await AppLang.set(value);
    if (!mounted) return;
    setState(() => _language = value);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bhasha save ho gayi'),
      backgroundColor: AppTheme.success,
    ));
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Namaste India'),
          ],
        ),
        content: const Text(
          'Version 1.0.0\n\nBharat ka apna cab app — surakshit, sahi daam, 24/7.\n\nMade with care in India.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Band karo')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Notifications'),
                _switchTile(
                  'Push notifications',
                  'Offers aur updates ki khabar',
                  Icons.notifications_outlined,
                  _notifications,
                  (v) {
                    setState(() => _notifications = v);
                    _saveBool(_prefsKeys['notifications']!, v);
                  },
                ),
                _switchTile(
                  'Ride updates',
                  'Driver milne aur ride shuru hone pe alert',
                  Icons.directions_car_outlined,
                  _rideUpdates,
                  (v) {
                    setState(() => _rideUpdates = v);
                    _saveBool(_prefsKeys['rideUpdates']!, v);
                  },
                ),
                const SizedBox(height: 16),
                _sectionTitle('Bhasha / Language'),
                _languageTile(),
                const SizedBox(height: 16),
                _sectionTitle('App'),
                _navTile(Icons.help_outline, 'Help & Support',
                    () => Nav.push(context, '/customer/support')),
                _navTile(Icons.emergency_outlined, 'Emergency SOS',
                    () => Nav.push(context, '/customer/sos')),
                _navTile(Icons.local_offer_outlined, 'Offers',
                    () => Nav.go(context, '/customer/offers')),
                _navTile(Icons.info_outline, 'About',
                    _showAbout),
                const SizedBox(height: 20),
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
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _switchTile(String title, String subtitle, IconData icon, bool value,
      ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppTheme.primary),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeColor: AppTheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _languageTile() => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.language, color: AppTheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('App ki bhasha',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              DropdownButton<String>(
                value: AppLang.supported.contains(_language)
                    ? _language
                    : 'Hinglish',
                underline: const SizedBox(),
                items: AppLang.supported
                    .map((l) =>
                        DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _saveLanguage(v);
                },
              ),
            ],
          ),
        ),
      );

  Widget _navTile(IconData icon, String title, VoidCallback onTap) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primary),
          title: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      );
}
