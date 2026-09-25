import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../admin_api.dart';

/// All bookings with status filters. Tap for a detail dialog.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  static const _filters = [
    'all',
    'pending',
    'driver_assigned',
    'started',
    'completed',
    'cancelled',
  ];

  static const _labels = {
    'all': 'All',
    'pending': 'Pending',
    'driver_assigned': 'Assigned',
    'started': 'Ongoing',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
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
      final res = await AdminApi.get('/api/admin/bookings');
      if (!mounted) return;
      setState(() {
        _bookings = AdminApi.asMapList(res['data']);
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

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _bookings
      : _bookings
          .where((b) => b['status']?.toString() == _filter)
          .toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      case 'driver_assigned':
        return AppTheme.primary;
      case 'started':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.textSecondary;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
      final ap = d.hour < 12 ? 'AM' : 'PM';
      return '${d.day} ${months[d.month - 1]}, $h:${d.minute.toString().padLeft(2, '0')} $ap';
    } catch (_) {
      return iso;
    }
  }

  String _personName(dynamic raw, String fallback) {
    if (raw is Map) return raw['name']?.toString() ?? fallback;
    return fallback;
  }

  String _personPhone(dynamic raw) {
    if (raw is Map) return raw['phone']?.toString() ?? '';
    return '';
  }

  double _fare(Map<String, dynamic> b) {
    final f = b['finalFare'] ?? b['estimatedFare'] ?? 0;
    return (f as num?)?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Bookings')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _errorView()
              : Column(
                  children: [
                    _filterRow(),
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

  Widget _filterRow() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final f = _filters[i];
          final active = _filter == f;
          final count = f == 'all'
              ? _bookings.length
              : _bookings.where((b) => b['status']?.toString() == f).length;
          return ChoiceChip(
            label: Text('${_labels[f]} ($count)'),
            selected: active,
            onSelected: (_) => setState(() => _filter = f),
            selectedColor: AppTheme.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              color: active ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          );
        },
      ),
    );
  }

  Widget _list() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(
        child: Text('Koi booking nahi mili.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (c, i) => _bookingCard(list[i]),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    final pickup = (b['pickup'] is Map)
        ? (b['pickup']['address']?.toString() ?? '')
        : '';
    final drop = (b['drop'] is Map)
        ? (b['drop']['address']?.toString() ?? '')
        : '';

    return GestureDetector(
      onTap: () => _showDetail(b),
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
                Expanded(
                  child: Text(
                    b['bookingNumber']?.toString() ?? 'Booking',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _labels[status] ?? status,
                    style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trip_origin,
                    size: 14, color: AppTheme.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(pickup.isEmpty ? '—' : pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppTheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(drop.isEmpty ? '—' : drop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${b['vehicleType']?.toString() ?? ''} • ${b['bookingType']?.toString() ?? ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Text('₹${_fare(b).round()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_fmtDate(b['createdAt']?.toString()),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> b) async {
    final driver = b['driverId'];
    final driverName = _personName(driver, 'Abhi assign nahi hua');
    final pickup = (b['pickup'] is Map)
        ? (b['pickup']['address']?.toString() ?? '—')
        : '—';
    final drop = (b['drop'] is Map)
        ? (b['drop']['address']?.toString() ?? '—')
        : '—';

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(b['bookingNumber']?.toString() ?? 'Booking'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dRow('Status', _labels[b['status']?.toString()] ??
                  b['status']?.toString() ?? '—'),
              _dRow('Customer', _personName(b['customerId'], 'Customer')),
              _dRow('Phone', _personPhone(b['customerId']).isEmpty
                  ? '—'
                  : _personPhone(b['customerId'])),
              _dRow('Driver', driverName),
              if (driver is Map && driver['vehicleNumber'] != null)
                _dRow('Vehicle No.', driver['vehicleNumber'].toString()),
              const Divider(height: 20),
              _dRow('Pickup', pickup),
              _dRow('Drop', drop),
              _dRow('Type',
                  '${b['bookingType'] ?? '-'} • ${b['vehicleType'] ?? '-'}'),
              if (b['distanceKm'] != null)
                _dRow('Distance', '${b['distanceKm']} km'),
              _dRow('Est. fare', '₹${_fare(b).round()}'),
              if (b['finalFare'] != null)
                _dRow('Final fare', '₹${(b['finalFare'] as num).round()}'),
              _dRow('Payment',
                  '${b['paymentMethod'] ?? 'pending'} (${b['paymentStatus'] ?? 'pending'})'),
              _dRow('Pickup time', _fmtDate(b['pickupTime']?.toString())),
              _dRow('Booked on', _fmtDate(b['createdAt']?.toString())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _dRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 92,
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
