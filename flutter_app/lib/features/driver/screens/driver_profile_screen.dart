import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";
import '../../../core/routes/nav.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});
  @override State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _loading = true;
  bool _toggling = false;
  String? _error;
  Map<String, dynamic>? _driver;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/profile"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final d = body is Map ? (body["driver"] ?? body["data"] ?? body) : null;
        final map = d == null ? null : Map<String, dynamic>.from(d as Map);
        setState(() {
          _driver = map;
          _online = (map?["isOnline"] ?? false) == true;
          _loading = false;
        });
      } else {
        setState(
            () { _error = "Profile load nahi hui (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  Future<void> _toggleOnline(bool v) async {
    setState(() => _toggling = true);
    try {
      final res = await http.patch(
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/status"),
        headers: await _headers(),
        body: jsonEncode({"isOnline": v}),
      );
      if (!mounted) return;
      setState(() => _toggling = false);
      if (res.statusCode == 200) {
        setState(() => _online = v);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(v ? "Online ho gaye — requests aayengi" : "Offline ho gaye"),
          backgroundColor: v ? AppTheme.success : AppTheme.textSecondary,
        ));
      } else if (res.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Wallet negative hai — pehle paise add karo"),
          backgroundColor: AppTheme.error,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Status update fail (code ${res.statusCode})"),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _toggling = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Network error"),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout?"),
        content: const Text("Kya aap sach me logout karna chahte ho?"),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("My Profile",
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                tooltip: "Refresh"),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || _driver == null
                ? _errorView()
                : _profile(),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error ?? "Profile nahi mili"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry")),
          ]),
        ),
      );

  Widget _profile() {
    final d = _driver!;
    final name = (d["name"] ?? "Driver").toString();
    final phone = (d["phone"] ?? "—").toString();
    final vehicle =
        "${d["vehicleType"] ?? ""} · ${d["vehicleNumber"] ?? ""}".trim();
    final rating = (d["rating"] ?? 0).toString();
    final trips = (d["totalTrips"] ?? 0).toString();
    final kyc = (d["kycStatus"] ?? "pending").toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _headerCard(name, phone, kyc),
        const SizedBox(height: 12),
        _onlineCard(),
        const SizedBox(height: 12),
        _statsRow(rating, trips, vehicle),
        const SizedBox(height: 12),
        _menuCard(),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: AppTheme.error),
          label: const Text("Logout",
              style: TextStyle(color: AppTheme.error)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ]),
    );
  }

  Widget _headerCard(String name, String phone, String kyc) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(Icons.person,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(phone,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        "KYC: ${kyc.toUpperCase()}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ])),
          ]),
        ),
      );

  Widget _onlineCard() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.circle,
                size: 12, color: _online ? AppTheme.success : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_online ? "Online ho" : "Offline ho",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Text("Requests paane ke liye online raho",
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ])),
            _toggling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: _online,
                    activeColor: AppTheme.success,
                    onChanged: _toggleOnline,
                  ),
          ]),
        ),
      );

  Widget _statsRow(String rating, String trips, String vehicle) => Row(
        children: [
          Expanded(child: _statTile(Icons.star, rating, "Rating")),
          const SizedBox(width: 12),
          Expanded(child: _statTile(Icons.route, trips, "Total Trips")),
        ],
      );

  Widget _statTile(IconData icon, String value, String label) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      );

  Widget _menuCard() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          _menuTile(Icons.account_balance_wallet_outlined, "Wallet",
              () => Nav.push(context, "/driver/wallet")),
          const Divider(height: 1, indent: 56),
          _menuTile(Icons.card_membership_outlined, "Subscription",
              () => Nav.push(context, "/driver/subscription")),
          const Divider(height: 1, indent: 56),
          _menuTile(Icons.badge_outlined, "KYC Documents",
              () => Nav.push(context, "/driver/kyc")),
          const Divider(height: 1, indent: 56),
          _menuTile(Icons.settings_outlined, "Settings",
              () => Nav.push(context, "/driver/settings")),
        ]),
      );

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right,
            color: AppTheme.textSecondary),
        onTap: onTap,
      );
}
