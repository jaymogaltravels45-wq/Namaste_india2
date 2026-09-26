import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";
import "../../../core/widgets/premium.dart";
import '../../../core/routes/nav.dart';

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
          Entrance(child: _balanceCard()),
          if (!_canAccept || _balance < 0) _blockedBanner(),
          const SizedBox(height: 20),
          const SectionTitle(title: 'Transactions'),
          const SizedBox(height: 10),
          if (_txs.isEmpty)
            const Entrance(
              delayMs: 120,
              child: PremiumEmpty(
                icon: Icons.receipt_long_rounded,
                title: 'No transactions yet',
                subtitle:
                    'Commission, recharge aur trip earnings yahin dikhengi.',
              ),
            )
          else
            ..._txs.asMap().entries.map(
                  (e) => Entrance(
                    delayMs: e.key * 60,
                    child: _txTile(e.value),
                  ),
                ),
        ],
      );

  Widget _balanceCard() {
    final negative = _balance < 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: negative
            ? const LinearGradient(
                colors: [Color(0xFFB42318), Color(0xFFD92D20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        boxShadow:
            negative ? null : AppTheme.shadowBlue,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text("Wallet Balance",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Pill(
                    text: negative ? 'BLOCKED' : 'ACTIVE',
                    color: negative
                        ? AppTheme.error
                        : AppTheme.success,
                    bg: Colors.white,
                    icon: negative
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                  ),
                ]),
                const SizedBox(height: 14),
                Text("Rs.${_balance.toStringAsFixed(0)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 4),
                Text(
                  negative
                      ? 'Balance negative — pehle recharge karo.'
                      : 'Bookings ke liye ready balance',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Nav.push(context, "/driver/add-money"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 18,
                            color: negative
                                ? AppTheme.error
                                : AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          "Add Money",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: negative
                                ? AppTheme.error
                                : AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
        ],
      ),
    );
  }

  Widget _blockedBanner() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppTheme.errorSoft,
            borderRadius:
                BorderRadius.circular(AppTheme.rMd),
            border:
                Border.all(color: AppTheme.error.withOpacity(0.35))),
        child: const Row(children: [
          Icon(Icons.block_rounded,
              color: AppTheme.error, size: 20),
          SizedBox(width: 10),
          Expanded(
              child: Text(
                  "Balance negative hai — bookings blocked! Paise add karo.",
                  style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13))),
        ]),
      );

  Widget _txTile(Map<String, dynamic> t) {
    final type = (t["type"] ?? "credit").toString();
    final isCredit = type == "credit";
    final amount = t["amount"]?.toString() ?? "0";
    final desc = (t["description"] ?? type).toString();
    final when = _fmtDate(t["createdAt"]);
    return PremiumCard(
      padding: const EdgeInsets.all(6),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: (isCredit ? AppTheme.success : AppTheme.error)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: isCredit ? AppTheme.success : AppTheme.error),
        ),
        title: Text(desc,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(when,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isCredit ? AppTheme.success : AppTheme.error)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
              "${isCredit ? "+" : "-"}Rs.$amount",
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: isCredit
                      ? AppTheme.success
                      : AppTheme.error)),
        ),
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
