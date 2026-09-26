import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Drivers whose KYC is still pending — approve or reject.
class AdminKycScreen extends StatefulWidget {
  const AdminKycScreen({super.key});

  @override
  State<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends State<AdminKycScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

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
      final all = AdminApi.asMapList(res['data']);
      if (!mounted) return;
      setState(() {
        _pending = all
            .where((d) => (d['kycStatus']?.toString() ?? 'pending') == 'pending')
            .toList();
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

  String _name(Map<String, dynamic> d) {
    final n = d['name']?.toString();
    if (n != null && n.isNotEmpty) return n;
    final u = d['userId'];
    if (u is Map && u['name'] != null) return u['name'].toString();
    return 'Driver';
  }

  Future<void> _decide(Map<String, dynamic> d, String status) async {
    final id = d['_id']?.toString() ?? '';
    setState(() => _busy.add(id));
    try {
      await AdminApi.patch('/api/admin/drivers/$id/kyc', {'status': status});
      if (!mounted) return;
      setState(() {
        _busy.remove(id);
        _pending.removeWhere((x) => x['_id']?.toString() == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'verified'
              ? '${_name(d)} ka KYC verify ho gaya.'
              : '${_name(d)} ka KYC reject kar diya.'),
          backgroundColor:
              status == 'verified' ? AppTheme.success : AppTheme.warning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('KYC Requests')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : _pending.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (c, i) => _kycCard(_pending[i]),
                      ),
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

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user_outlined,
                size: 72, color: AppTheme.success),
            SizedBox(height: 16),
            Text('Sab clear!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Koi pending KYC request nahi hai.',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _kycCard(Map<String, dynamic> d) {
    final id = d['_id']?.toString() ?? '';
    final busy = _busy.contains(id);
    final phone = d['phone']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.warning.withOpacity(0.15),
                child: Text(
                  _name(d).isEmpty ? '?' : _name(d)[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.warning, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name(d),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(phone,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('PENDING',
                    style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Vehicle',
              '${d['vehicleType']?.toString() ?? '-'} • ${d['vehicleNumber']?.toString() ?? '-'}'),
          _row('Model', '${d['vehicleModel']?.toString() ?? '-'}'),
          _row('License', '${d['licenseNumber']?.toString() ?? '-'}'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed:
                        busy ? null : () => _decide(d, 'verified'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Approve'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _decide(d, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
                width: 80,
                child: Text(k,
                    style:
                        const TextStyle(color: AppTheme.textSecondary))),
            Expanded(
                child: Text(v,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
