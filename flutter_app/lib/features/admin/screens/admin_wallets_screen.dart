import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Driver wallet balances with credit/debit adjustment.
class AdminWalletsScreen extends StatefulWidget {
  const AdminWalletsScreen({super.key});

  @override
  State<AdminWalletsScreen> createState() => _AdminWalletsScreenState();
}

class _AdminWalletsScreenState extends State<AdminWalletsScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApi.get('/api/admin/drivers');
      if (!mounted) return;
      final list = AdminApi.asMapList(res['data'])
        ..sort((a, b) => _bal(a).compareTo(_bal(b)));
      setState(() {
        _drivers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  double _bal(Map<String, dynamic> d) =>
      (d['walletBalance'] as num?)?.toDouble() ?? 0;

  String _name(Map<String, dynamic> d) {
    final n = d['name']?.toString();
    if (n != null && n.isNotEmpty) return n;
    final u = d['userId'];
    if (u is Map && u['name'] != null) return u['name'].toString();
    return 'Driver';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Driver Wallets')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _summaryBar(),
                    Expanded(child: _list()),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error ?? 'Load failed',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _summaryBar() {
    final negative =
        _drivers.where((d) => _bal(d) < 0).length;
    final total =
        _drivers.fold<double>(0, (s, d) => s + _bal(d));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('${_drivers.length}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Drivers',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('₹${total.round()}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Total balance',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('$negative',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: negative > 0
                            ? AppTheme.error
                            : AppTheme.textPrimary)),
                const Text('Negative (blocked)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    if (_drivers.isEmpty) {
      return const Center(
        child: Text('Koi driver nahi mila.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _drivers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (c, i) {
          final d = _drivers[i];
          final bal = _bal(d);
          final blocked = d['canAcceptBookings'] == false;
          return GestureDetector(
            onTap: () => _adjustDialog(d),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: bal < 0
                      ? AppTheme.error.withOpacity(0.4)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (bal < 0
                            ? AppTheme.error
                            : const Color(0xFFC2185B))
                        .withOpacity(0.12),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: bal < 0
                          ? AppTheme.error
                          : const Color(0xFFC2185B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name(d),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          blocked
                              ? 'Blocked — negative balance'
                              : (d['isOnline'] == true
                                  ? 'Online • trips le sakta hai'
                                  : 'Bookings le sakta hai'),
                          style: TextStyle(
                            fontSize: 12,
                            color: blocked
                                ? AppTheme.error
                                : AppTheme.textSecondary,
                            fontWeight: blocked
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${bal.round()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: bal < 0
                                ? AppTheme.error
                                : AppTheme.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      const Text('Tap to adjust',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _adjustDialog(Map<String, dynamic> d) async {
    final id = d['_id']?.toString() ?? '';
    final amtCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'credit';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: Text('Wallet — ${_name(d)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ₹${_bal(d).round()}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(
                      value: 'credit', child: Text('Credit (+)')),
                  DropdownMenuItem(
                      value: 'debit', child: Text('Debit (−)')),
                ],
                onChanged: (v) => setS(() => type = v ?? 'credit'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason / note',
                  hintText: 'e.g. Weekly bonus',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amt = double.tryParse(amtCtrl.text.trim());
                      if (amt == null || amt <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sahi amount dalen.'),
                              backgroundColor: AppTheme.error),
                        );
                        return;
                      }
                      setS(() => saving = true);
                      try {
                        await AdminApi.patch(
                            '/api/admin/drivers/$id/wallet', {
                          'amount': type == 'credit' ? amt : -amt,
                          'type': type,
                          'description': descCtrl.text.trim().isEmpty
                              ? 'Admin adjustment'
                              : descCtrl.text.trim(),
                        });
                        if (!mounted) return;
                        Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Wallet update ho gaya.'),
                              backgroundColor: AppTheme.success),
                        );
                        _load();
                      } catch (e) {
                        setS(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e
                                .toString()
                                .replaceFirst('Exception: ', '')),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amtCtrl.dispose();
    descCtrl.dispose();
  }
}
