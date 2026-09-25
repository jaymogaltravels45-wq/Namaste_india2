import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Fare tables from GET /api/fare/rates (vehicleRates + localRates).
class AdminFaresScreen extends StatefulWidget {
  const AdminFaresScreen({super.key});

  @override
  State<AdminFaresScreen> createState() => _AdminFaresScreenState();
}

class _AdminFaresScreenState extends State<AdminFaresScreen> {
  Map<String, dynamic> _vehicleRates = {};
  Map<String, dynamic> _localRates = {};
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
      final res = await AdminApi.get('/api/fare/rates');
      if (!mounted) return;
      setState(() {
        _vehicleRates = AdminApi.asMap(res['vehicleRates']);
        _localRates = AdminApi.asMap(res['localRates']);
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

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Fare Management')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _infoBanner(),
                      const SizedBox(height: 16),
                      const Text('Outstation Fares',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ..._vehicleRates.keys.map(_outstationCard),
                      const SizedBox(height: 20),
                      const Text('Local Packages',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ..._localRates.keys.map(_localCard),
                      const SizedBox(height: 24),
                    ],
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

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: const Text(
        'Outstation: 100 km tak fixed fare, uske baad per-km charge.\n'
        'Local: 3 packages per vehicle (4h/40km, 8h/80km, 12h/120km).',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
    );
  }

  Widget _outstationCard(String vehicle) {
    final r = AdminApi.asMap(_vehicleRates[vehicle]);
    final base = (r['base'] as num?)?.round() ?? 0;
    final perKm = (r['perKm'] as num?)?.round() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: AppTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_cap(vehicle),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('₹$base fixed (0–100 km)  •  +₹$perKm/km after 100 km',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _localCard(String vehicle) {
    final pkgs = AdminApi.asMap(_localRates[vehicle]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_cap(vehicle),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...pkgs.keys.map((pkg) {
            final fare = (pkgs[pkg] as num?)?.round() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(pkg,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                  const Spacer(),
                  Text('₹$fare',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
