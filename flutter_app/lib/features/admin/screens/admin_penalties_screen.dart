import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Apply a penalty: deducts from the driver's wallet via
/// PATCH /api/admin/drivers/:id/wallet {amount: negative, type:'penalty'}.
class AdminPenaltiesScreen extends StatefulWidget {
  const AdminPenaltiesScreen({super.key});

  @override
  State<AdminPenaltiesScreen> createState() => _AdminPenaltiesScreenState();
}

class _AdminPenaltiesScreenState extends State<AdminPenaltiesScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String? _selectedId;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApi.get('/api/admin/drivers');
      if (!mounted) return;
      setState(() {
        _drivers = AdminApi.asMapList(res['data']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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

  Map<String, dynamic>? get _selected {
    for (final d in _drivers) {
      if (d['_id']?.toString() == _selectedId) return d;
    }
    return null;
  }

  Future<void> _apply() async {
    final d = _selected;
    final amt = double.tryParse(_amountCtrl.text.trim());
    final reason = _reasonCtrl.text.trim();

    if (d == null) {
      _snack('Pehle driver chunein.', true);
      return;
    }
    if (amt == null || amt <= 0) {
      _snack('Sahi penalty amount dalen.', true);
      return;
    }
    if (reason.length < 3) {
      _snack('Penalty ka reason likhein.', true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Penalty confirm karo'),
        content: Text(
          '${_name(d)} ke wallet se ₹${amt.round()} katega.\nReason: $reason\n\nNegative balance par driver block ho jayega.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Apply Penalty'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      final res = await AdminApi.patch(
          '/api/admin/drivers/${d['_id']}/wallet', {
        'amount': -amt,
        'type': 'penalty',
        'description': 'Penalty: $reason',
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _selectedId = null;
        _amountCtrl.clear();
        _reasonCtrl.clear();
      });
      final newBal = (res['newBalance'] as num?)?.round();
      _snack(
          'Penalty lag gaya. New balance: ₹$newBal', false);
      _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''), true);
    }
  }

  void _snack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Penalties')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Penalty driver ke wallet se turant kat jayega.\n'
                    'Balance negative hote hi driver bookings nahi le payega.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedId,
                  hint: const Text('Driver chunein'),
                  items: _drivers.map((d) {
                    final id = d['_id']?.toString() ?? '';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        '${_name(d)} • ${_phone(d)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedId = v),
                  decoration: const InputDecoration(
                    labelText: 'Driver',
                    prefixIcon: Icon(Icons.person_search_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Penalty amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'e.g. Customer complaint — rude behaviour',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      '${_name(_selected!)} ka current balance: ₹${((_selected!['walletBalance'] as num?) ?? 0).round()}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _apply,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Apply Penalty',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}
