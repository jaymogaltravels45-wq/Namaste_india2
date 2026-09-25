import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});
  @override State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  bool _loading = true;
  String? _error;
  double _balance = 0;
  bool _canAccept = true;
  List<Map<String, dynamic>> _txs = [];

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
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/wallet"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = (body["transactions"] ?? []) as List;
        setState(() {
          _balance = (body["balance"] is num)
              ? (body["balance"] as num).toDouble()
              : double.tryParse(body["balance"].toString()) ?? 0;
          _canAccept = (body["canAcceptBookings"] ?? true) == true;
          _txs = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      } else {
        setState(
            () { _error = "Wallet load nahi hua (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("My Wallet",
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
            : _error != null
                ? _errorView()
                : RefreshIndicator(onRefresh: _load, child: _body()),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry")),
          ]),
        ),
      );

  Widget _body() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _balanceCard(),
          if (!_canAccept || _balance < 0) _blockedBanner(),
          const SizedBox(height: 20),
          const Text("Transactions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_txs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text("Abhi koi transaction nahi hai",
                        style: TextStyle(
                            color: AppTheme.textSecondary))),
              ),
            )
          else
            ..._txs.map(_txTile),
        ],
      );

  Widget _balanceCard() {
    final negative = _balance < 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: negative
            ? [const Color(0xFFB71C1C), const Color(0xFFE53935)]
            : [const Color(0xFF0D47A1), const Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.account_balance_wallet,
              color: Colors.white70, size: 20),
          SizedBox(width: 8),
          Text("Wallet Balance",
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text("Rs.${_balance.toStringAsFixed(0)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.go("/driver/add-money"),
              icon: const Icon(Icons.add),
              label: const Text("Add Money"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: negative
                    ? const Color(0xFFB71C1C)
                    : AppTheme.primary,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _blockedBanner() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.error.withOpacity(0.4))),
        child: const Row(children: [
          Icon(Icons.block, color: AppTheme.error, size: 20),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  "Balance negative hai — bookings blocked! Paise add karo.",
                  style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13))),
        ]),
      );

  Widget _txTile(Map<String, dynamic> t) {
    final type = (t["type"] ?? "credit").toString();
    final isCredit = type == "credit";
    final amount = t["amount"]?.toString() ?? "0";
    final desc = (t["description"] ?? type).toString();
    final when = _fmtDate(t["createdAt"]);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: (isCredit ? AppTheme.success : AppTheme.error)
                  .withOpacity(0.12),
              shape: BoxShape.circle),
          child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 18,
              color: isCredit ? AppTheme.success : AppTheme.error),
        ),
        title: Text(desc,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(when,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
        trailing: Text(
            "${isCredit ? "+" : "-"}Rs.$amount",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCredit
                    ? AppTheme.success
                    : AppTheme.error)),
      ),
    );
  }

  String _fmtDate(dynamic v) {
    if (v == null) return "";
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, "0")}";
    } catch (_) {
      return v.toString();
    }
  }
}
