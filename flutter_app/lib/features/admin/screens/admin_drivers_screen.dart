import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// All drivers with status chips. Tap a driver for detail + actions
/// (verify KYC, adjust wallet).
class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApi.get('/api/admin/drivers');
      if (!mounted) return;
      setState(() {
        _drivers = AdminApi.asMapList(res['data']);
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

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _drivers;
    final q = _query.toLowerCase();
    return _drivers.where((d) {
      return _name(d).toLowerCase().contains(q) ||
          _phone(d).contains(q) ||
          (d['vehicleNumber']?.toString() ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _name(Map<String, dynamic> d) {
    final n = d['name']?.toString();
    if (n != null && n.isNotEmpty) return n;
    final u = d['userId'];
    if (u is Map && u['name'] != null) return u['name'].toString();
    return 'Driver';
  }

  String _phone(Map<String, dynamic> d) {
    final p = d['phone']?.toString();
    if (p != null && p.isNotEmpty) return p;
    final u = d['userId'];
    if (u is Map && u['phone'] != null) return u['phone'].toString();
    return '';
  }

  double _balance(Map<String, dynamic> d) =>
      (d['walletBalance'] as num?)?.toDouble() ?? 0;

  Color _kycColor(String s) {
    switch (s) {
      case 'verified':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Drivers')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _searchBar(),
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          hintText: 'Naam, phone ya gaadi number…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _list() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(
        child: Text('Koi driver nahi mila.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (c, i) => _driverCard(list[i]),
      ),
    );
  }

  Widget _driverCard(Map<String, dynamic> d) {
    final name = _name(d);
    final kyc = (d['kycStatus']?.toString() ?? 'pending');
    final online = d['isOnline'] == true;
    final bal = _balance(d);
    final blocked = d['canAcceptBookings'] == false;

    return GestureDetector(
      onTap: () => _showDetail(d),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFF2E7D32).withOpacity(0.12),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${_phone(d)} • ${d['vehicleType']?.toString() ?? ''} ${d['vehicleNumber']?.toString() ?? ''}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${bal.round()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: bal < 0 ? AppTheme.error : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('KYC: $kyc', _kycColor(kyc)),
                _chip(online ? 'Online' : 'Offline',
                    online ? AppTheme.success : AppTheme.textSecondary),
                if (blocked) _chip('Blocked', AppTheme.error),
                if (d['totalTrips'] != null)
                  _chip('${d['totalTrips']} trips', AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> d) async {
    final id = d['_id']?.toString() ?? '';
    final name = _name(d);
    final kyc = d['kycStatus']?.toString() ?? 'pending';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(c).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_phone(d),
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            _row('Gaadi',
                '${d['vehicleType'] ?? '-'} • ${d['vehicleNumber'] ?? '-'}'),
            _row('Model', '${d['vehicleModel'] ?? '-'}'),
            _row('License', '${d['licenseNumber'] ?? '-'}'),
            _row('KYC', kyc),
            _row('Wallet', '₹${_balance(d).round()}'),
            _row('Rating', '${d['rating'] ?? 0} (${d['totalTrips'] ?? 0} trips)'),
            const SizedBox(height: 20),
            if (kyc == 'pending')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Verify KYC'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                  onPressed: () async {
                    Navigator.pop(c);
                    await _kycAction(id, 'verified');
                  },
                ),
              ),
            if (kyc == 'pending') const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Wallet Adjust Karo'),
                onPressed: () {
                  Navigator.pop(c);
                  _walletDialog(d);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style:
                        const TextStyle(color: AppTheme.textSecondary))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Future<void> _kycAction(String id, String status) async {
    try {
      await AdminApi.patch('/api/admin/drivers/$id/kyc', {'status': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'verified'
              ? 'KYC verify ho gaya.'
              : 'KYC reject kar diya.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _walletDialog(Map<String, dynamic> d) async {
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
              Text('Current balance: ₹${_balance(d).round()}',
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
                  hintText: 'e.g. Bonus, adjustment',
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
                        final signed =
                            type == 'credit' ? amt : -amt;
                        await AdminApi.patch(
                            '/api/admin/drivers/$id/wallet', {
                          'amount': signed,
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
