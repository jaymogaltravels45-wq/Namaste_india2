import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});
  @override State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _notifications = true;
  bool _tripAlerts = true;
  bool _location = true;
  String _language = "Hinglish";

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout?"),
        content:
            const Text("Kya aap sach me logout karna chahte ho?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Nahi")),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Haan, logout")),
        ],
      ),
    );
    if (ok != true) return;
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go("/welcome");
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: "1.0.0",
      applicationLegalese: "Namaste India Cab Services",
      children: const [
        SizedBox(height: 8),
        Text("Driver app — safe aur fair rides ke liye."),
      ],
    );
  }

  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Language chuno",
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          for (final lang in ["Hinglish", "English", "Hindi"])
            RadioListTile<String>(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              activeColor: AppTheme.primary,
              onChanged: (v) {
                setState(() => _language = v ?? "Hinglish");
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Language: $_language")),
                );
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Settings",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Notifications",
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            _section([
              SwitchListTile(
                title: const Text("Push notifications"),
                subtitle: const Text("Nayi requests ki khabar"),
                value: _notifications,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              const Divider(height: 1, indent: 16),
              SwitchListTile(
                title: const Text("Trip alerts"),
                subtitle: const Text("Start/complete yaad dilao"),
                value: _tripAlerts,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _tripAlerts = v),
              ),
            ]),
            const SizedBox(height: 20),
            const Text("Privacy",
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            _section([
              SwitchListTile(
                title: const Text("Location sharing"),
                subtitle: const Text("Trip ke time live location"),
                value: _location,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _location = v),
              ),
            ]),
            const SizedBox(height: 20),
            const Text("General",
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            _section([
              ListTile(
                leading: const Icon(Icons.language,
                    color: AppTheme.primary),
                title: const Text("Language"),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_language,
                      style: const TextStyle(
                          color: AppTheme.textSecondary)),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                ]),
                onTap: _pickLanguage,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.info_outline,
                    color: AppTheme.primary),
                title: const Text("About"),
                subtitle: Text("${AppConfig.appName} v1.0.0"),
                trailing: const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary),
                onTap: _showAbout,
              ),
            ]),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout,
                  color: AppTheme.error),
              label: const Text("Logout",
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppTheme.error),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text("Namaste India · Driver v1.0.0",
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary)),
            ),
          ],
        ),
      );

  Widget _section(List<Widget> children) => Card(
        margin: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: children),
      );
}
