import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

/// Premium subscription: Rs.300 / 30 days = 0% commission.
/// Without premium: 5% commission on every completed trip.
class DriverSubscriptionScreen extends StatefulWidget {
  const DriverSubscriptionScreen({super.key});
  @override
  State<DriverSubscriptionScreen> createState() =>
      _DriverSubscriptionScreenState();
}

class _DriverSubscriptionScreenState extends State<DriverSubscriptionScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _active = false;
  String? _endsAt;

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
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/subscriptions/status"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _active = body["active"] == true;
          _endsAt = body["endsAt"]?.toString();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _buy() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Premium lo?"),
        content: const Text(
            "Rs.300 wallet se katenge. 30 din tak 0% commission milega."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Confirm")),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/subscriptions/buy"),
        headers: await _headers(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final body = jsonDecode(res.body);
      if (res.statusCode == 201 && body["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Premium activate! 30 din 0% commission 🎉"),
          backgroundColor: AppTheme.success,
        ));
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              (body["message"] ?? "Buy nahi ho paya").toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Network error"),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Subscription",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusCard(),
                      const SizedBox(height: 20),
                      const Text("Premium Plan",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _planCard(),
                      const SizedBox(height: 12),
                      const Text(
                        "Premium nahi hai to har complete trip par 5% commission katega. Wallet negative hone par nayi booking accept nahi hogi.",
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ]),
              ),
      );

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _active
              ? const [Color(0xFF2E7D32), Color(0xFF66BB6A)]
              : const [Color(0xFF616161), Color(0xFF9E9E9E)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(
              _active
                  ? Icons.workspace_premium
                  : Icons.workspace_premium_outlined,
              color: Colors.white,
              size: 36),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text("Status",
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(_active ? "PREMIUM ACTIVE" : "NO PREMIUM",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                if (_active && _endsAt != null)
                  Text("Valid till: ${_fmtDate(_endsAt!)}",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                if (!_active)
                  const Text("Commission: 5% per trip",
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
              ])),
        ]),
      );

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return iso;
    }
  }

  Widget _planCard() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Expanded(
                  child: Text("Premium",
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold))),
              Text("Rs.300",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
            ]),
            const SizedBox(height: 2),
            const Text("30 din · 0% commission",
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            ...[
              "30 din tak 0% commission",
              "Priority me naye requests",
              "Wallet se direct payment",
            ].map((perk) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(perk,
                            style:
                                const TextStyle(fontSize: 13))),
                  ]),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_active || _busy) ? null : _buy,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _active
                        ? Colors.grey.shade300
                        : AppTheme.primary,
                    foregroundColor:
                        _active ? Colors.grey.shade600 : Colors.white),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_active
                        ? "Active Hai"
                        : "Rs.300 me Premium Lo"),
              ),
            ),
          ]),
        ),
      );
}
