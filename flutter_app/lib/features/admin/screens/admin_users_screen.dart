import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Customer list derived from bookings (customerId is populated
/// with name+phone by the backend). Includes search.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _customers = [];
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
      final res = await AdminApi.get('/api/admin/bookings');
      final bookings = AdminApi.asMapList(res['data']);

      final map = <String, Map<String, dynamic>>{};
      for (final b in bookings) {
        final cRaw = b['customerId'];
        final id = cRaw is Map
            ? (cRaw['_id']?.toString() ?? 'unknown')
            : cRaw.toString();
        final name = cRaw is Map
            ? (cRaw['name']?.toString() ?? 'Customer')
            : 'Customer';
        final phone =
            cRaw is Map ? (cRaw['phone']?.toString() ?? '') : '';
        final fare = b['finalFare'] ?? b['estimatedFare'] ?? 0;

        final entry = map.putIfAbsent(id, () => {
              'id': id,
              'name': name,
              'phone': phone,
              'trips': 0,
              'spent': 0.0,
            });
        entry['trips'] = (entry['trips'] as int) + 1;
        entry['spent'] =
            (entry['spent'] as double) + (fare is num ? fare.toDouble() : 0);
      }

      final list = map.values.toList()
        ..sort((a, b) => (b['trips'] as int).compareTo(a['trips'] as int));

      if (!mounted) return;
      setState(() {
        _customers = list;
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
    if (_query.isEmpty) return _customers;
    final q = _query.toLowerCase();
    return _customers
        .where((c) =>
            c['name'].toString().toLowerCase().contains(q) ||
            c['phone'].toString().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Users (Customers)')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _summaryBar(),
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

  Widget _summaryBar() {
    final totalTrips =
        _customers.fold<int>(0, (s, c) => s + (c['trips'] as int));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _summaryCell('${_customers.length}', 'Total customers'),
          _vDivider(),
          _summaryCell('$totalTrips', 'Total trips'),
          _vDivider(),
          _summaryCell(
            '₹${_customers.fold<double>(0, (s, c) => s + (c['spent'] as double)).round()}',
            'Lifetime value',
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(l,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      );

  Widget _vDivider() => Container(
      width: 1, height: 36, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          hintText: 'Naam ya phone se khojo…',
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
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Koi customer nahi mila.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (c, i) {
          final u = list[i];
          final name = u['name'].toString();
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppTheme.primary.withOpacity(0.12),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primary,
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
                          (u['phone'] as String).isEmpty
                              ? 'Phone nahi diya'
                              : u['phone'].toString(),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${u['trips']} trips',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('₹${(u['spent'] as double).round()}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
