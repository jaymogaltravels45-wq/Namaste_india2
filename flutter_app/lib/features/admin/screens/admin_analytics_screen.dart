import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// Analytics built from real backend data: dashboard counts +
/// booking-status distribution. Custom bars, no chart package.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _dash = {};
  Map<String, int> _statusCounts = {};
  bool _loading = true;
  String? _error;

  static const _statusMeta = {
    'pending': ['Pending', AppTheme.warning],
    'driver_assigned': ['Assigned', AppTheme.primary],
    'started': ['Ongoing', Color(0xFF6A1B9A)],
    'completed': ['Completed', AppTheme.success],
    'cancelled': ['Cancelled', AppTheme.error],
  };

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
      final dashRes = await AdminApi.get('/api/admin/dashboard');
      final bookRes = await AdminApi.get('/api/admin/bookings');
      if (!mounted) return;

      final counts = <String, int>{
        for (final s in _statusMeta.keys) s: 0,
      };
      for (final b in AdminApi.asMapList(bookRes['data'])) {
        final s = b['status']?.toString() ?? 'pending';
        counts[s] = (counts[s] ?? 0) + 1;
      }

      setState(() {
        _dash = AdminApi.asMap(dashRes['data']);
        _statusCounts = counts;
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

  int _int(String key) => (_dash[key] as num?)?.toInt() ?? 0;

  String _inr(num v) {
    final s = v.round().toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Analytics')),
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
                      _revenueCard(),
                      const SizedBox(height: 16),
                      _section('Platform Growth', [
                        _BarData('Customers', _int('customers'),
                            const Color(0xFF1565C0)),
                        _BarData('Drivers', _int('drivers'),
                            const Color(0xFF2E7D32)),
                        _BarData('Bookings', _int('bookings'),
                            const Color(0xFF6A1B9A)),
                      ]),
                      const SizedBox(height: 16),
                      _section('Bookings by Status', [
                        for (final s in _statusMeta.keys)
                          _BarData(
                            _statusMeta[s]![0] as String,
                            _statusCounts[s] ?? 0,
                            _statusMeta[s]![1] as Color,
                          ),
                      ]),
                      const SizedBox(height: 16),
                      _section('Attention Needed', [
                        _BarData('Pending KYC', _int('pendingKyc'),
                            AppTheme.warning),
                        _BarData('Cancelled trips',
                            _statusCounts['cancelled'] ?? 0, AppTheme.error),
                      ]),
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

  Widget _revenueCard() {
    final revenue = (_dash['revenue'] as num?) ?? 0;
    final bookings = _int('bookings');
    final avg = bookings > 0 ? revenue / bookings : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Revenue',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('₹${_inr(revenue)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Avg per booking: ₹${avg.round()}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<_BarData> bars) {
    final max =
        bars.map((b) => b.value).fold<int>(1, (a, b) => b > a ? b : a);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: _SectionMax(
        max: max,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final b in bars)
              _BarRow(label: b.label, value: b.value, color: b.color),
          ],
        ),
      ),
    );
  }
}

/// Inherited max value so every bar in a section normalizes
/// against the same scale.
class _SectionMax extends InheritedWidget {
  final int max;
  const _SectionMax({required this.max, required super.child});

  static int of(BuildContext context) {
    final w =
        context.dependOnInheritedWidgetOfExactType<_SectionMax>();
    return w?.max ?? 1;
  }

  @override
  bool updateShouldNotify(_SectionMax old) => old.max != max;
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BarRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final max = _SectionMax.of(context);
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.02, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.border.withOpacity(0.6),
                borderRadius: BorderRadius.circular(9),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: frac,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
