import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});
  @override State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _amountCtrl = TextEditingController();
  bool _busy = false;
  final _quick = [500, 1000, 2000, 5000];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<void> _addMoney() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Kam se kam Rs.10 daalo"),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/wallet/add"),
        headers: await _headers(),
        body: jsonEncode({"amount": amount}),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final bal = body["balance"]?.toString() ?? "";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Rs.${amount.toStringAsFixed(0)} add ho gaye! Balance: Rs.$bal"),
          backgroundColor: AppTheme.success,
        ));
        context.go("/driver/wallet");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Payment fail (code ${res.statusCode})"),
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
          title: const Text("Add Money",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                    ]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(children: [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text("Wallet me paise add karo",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        "Negative balance pe bookings block ho jati hain",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 24),
                const Text("Amount",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: "Rs. ",
                    hintText: "1000",
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: _quick
                      .map((q) => ChoiceChip(
                            label: Text("Rs.$q"),
                            selected:
                                _amountCtrl.text == q.toString(),
                            onSelected: (_) => setState(
                                () => _amountCtrl.text = q.toString()),
                            selectedColor:
                                AppTheme.primary.withOpacity(0.15),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Row(children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          "Payment UPI se hoga — company ke QR pe pay karo",
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary))),
                ]),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _addMoney,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14)),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _amountCtrl.text.isEmpty
                              ? "Add Money"
                              : "Rs.${_amountCtrl.text} Add Karo",
                          style: const TextStyle(fontSize: 16)),
                ),
              ]),
        ),
      );
}
