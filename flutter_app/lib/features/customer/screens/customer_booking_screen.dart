import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/widgets/map_location_picker.dart';

class CustomerBookingScreen extends StatefulWidget {
  final String? type;
  const CustomerBookingScreen({super.key, this.type});

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _bidCtrl = TextEditingController();
  PickedLocation? _pickupLoc;
  PickedLocation? _dropLoc;

  String _vehicle = 'sedan';
  String _localPkg = '8h/80km';
  DateTime? _pickupTime;
  bool _loadingFare = false;
  bool _booking = false;
  Map<String, dynamic>? _fare;

  static const _vehicles = ['hatchback', 'sedan', 'suv', 'innova'];
  static const _packages = ['4h/40km', '8h/80km', '12h/120km'];

  String get _kind => widget.type ?? 'outstation';
  String get _backendType => _kind == 'round' ? 'round_trip' : _kind;

  String get _title {
    switch (_kind) {
      case 'local':
        return 'Local Package';
      case 'round':
        return 'Round Trip';
      case 'bid':
        return 'Bid a Ride';
      default:
        return 'One Way Trip';
    }
  }

  String _vehicleLabel(String v) {
    switch (v) {
      case 'hatchback':
        return 'Hatchback';
      case 'suv':
        return 'SUV';
      case 'innova':
        return 'Innova';
      default:
        return 'Sedan';
    }
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
    ));
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    setState(() {
      _pickupTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _fmtDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$h:$mm $ampm, ${dt.day} ${months[dt.month - 1]}';
  }

  Future<void> _getFare() async {
    if (_kind == 'bid') return;
    setState(() {
      _loadingFare = true;
      _fare = null;
    });
    try {
      http.Response res;
      if (_kind == 'local') {
        res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/fare/local'),
          headers: _headers(),
          body: jsonEncode(
              {'vehicleType': _vehicle, 'localPackage': _localPkg}),
        );
      } else {
        final km = double.tryParse(_kmCtrl.text.trim()) ?? 0;
        if (km <= 0) {
          _snack('Distance (km) daaliye', error: true);
          setState(() => _loadingFare = false);
          return;
        }
        res = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/fare/outstation'),
          headers: _headers(),
          body: jsonEncode({'vehicleType': _vehicle, 'distanceKm': km}),
        );
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        setState(() => _fare = body);
      } else {
        _snack(body['message']?.toString() ?? 'Fare nahi mil paya',
            error: true);
      }
    } catch (e) {
      _snack('Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingFare = false);
    }
  }

  Future<void> _pickOnMap(bool isPickup) async {
    final res = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: isPickup ? 'Pickup Location' : 'Drop Location',
          initial: isPickup ? _pickupLoc : _dropLoc,
        ),
      ),
    );
    if (res == null || !mounted) return;
    setState(() {
      if (isPickup) {
        _pickupLoc = res;
        _pickupCtrl.text = res.address;
      } else {
        _dropLoc = res;
        _dropCtrl.text = res.address;
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_pickupCtrl.text.trim().isEmpty) {
      _snack('Pickup address likhiye', error: true);
      return;
    }
    if (_kind != 'local' && _dropCtrl.text.trim().isEmpty) {
      _snack('Drop address likhiye', error: true);
      return;
    }
    if (_kind != 'local' && _kind != 'bid') {
      final km = double.tryParse(_kmCtrl.text.trim()) ?? 0;
      if (km <= 0) {
        _snack('Distance (km) daaliye', error: true);
        return;
      }
    }
    setState(() => _booking = true);
    try {
      final payload = <String, dynamic>{
        'bookingType': _backendType,
        'vehicleType': _vehicle,
        'pickup': {
          'address': _pickupCtrl.text.trim(),
          if (_pickupLoc != null)
            'location': {
              'type': 'Point',
              'coordinates': [_pickupLoc!.lng, _pickupLoc!.lat],
            },
        },
        'drop': {
          'address': _dropCtrl.text.trim(),
          if (_dropLoc != null)
            'location': {
              'type': 'Point',
              'coordinates': [_dropLoc!.lng, _dropLoc!.lat],
            },
        },
        'pickupTime':
            (_pickupTime ?? DateTime.now().add(const Duration(hours: 1)))
                .toIso8601String(),
      };
      if (_kind == 'local') {
        payload['localPackage'] = _localPkg;
      } else if (_kind == 'bid') {
        final bid = double.tryParse(_bidCtrl.text.trim()) ?? 0;
        if (bid <= 0) {
          _snack('Apni bid amount (₹) daaliye', error: true);
          return;
        }
        payload['customerBid'] = bid;
      } else if (_kind != 'bid') {
        payload['distanceKm'] = double.tryParse(_kmCtrl.text.trim()) ?? 0;
      }
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/bookings'),
        headers: _headers(),
        body: jsonEncode(payload),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body['success'] == true) {
        final booking = body['booking'] as Map<String, dynamic>;
        final id = booking['_id']?.toString() ?? '';
        _snack('Booking ho gayi! Driver dhoondh rahe hain...');
        context.go('/customer/booking/$id');
      } else {
        _snack(body['message']?.toString() ?? 'Booking fail ho gayi',
            error: true);
      }
    } catch (e) {
      _snack('Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _kmCtrl.dispose();
    _bidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            _locationRow(
              label: 'Pickup location',
              hint: 'Map pe select karo',
              icon: Icons.my_location,
              ctrl: _pickupCtrl,
              onTap: () => _pickOnMap(true),
            ),
            const SizedBox(height: 12),
            if (_kind != 'local')
              _locationRow(
                label: 'Drop location',
                hint: 'Map pe select karo',
                icon: Icons.location_on,
                ctrl: _dropCtrl,
                onTap: () => _pickOnMap(false),
              ),
            if (_kind != 'local') const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdownField(
                    'Gaadi',
                    _vehicle,
                    _vehicles.map(_vehicleLabel).toList(),
                    _vehicles,
                    (v) => setState(() => _vehicle = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kind == 'local'
                      ? _dropdownField('Package', _localPkg, _packages,
                          _packages, (v) => setState(() => _localPkg = v!))
                      : _textField('Distance (km)', _kmCtrl,
                          Icons.straighten, 'e.g. 120',
                          numeric: true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _dateTimeTile(),
            const SizedBox(height: 16),
            if (_kind == 'bid') ...[
              _textField('Tumhari bid (₹)', _bidCtrl, Icons.currency_rupee,
                  'e.g. 1500',
                  numeric: true),
              const SizedBox(height: 12),
              _bidNote(),
            ] else
              _fareSection(),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _booking ? null : _confirmBooking,
                child: _booking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _kind == 'bid' ? 'Bid Bhejo' : 'Confirm Booking',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          boxShadow: AppTheme.shadowBlue,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.14),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.shadowGold,
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(
                        _kind == 'local'
                            ? 'Sheher ke andar fixed package'
                            : _kind == 'bid'
                                ? 'Apna rate lagao, driver accept karega'
                                : '100 km tak fixed, uske baad per-km',
                        style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Tappable location row that opens the map picker.
  Widget _locationRow({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController ctrl,
    required VoidCallback onTap,
  }) {
    final hasValue = ctrl.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              border: Border.all(
                  color: hasValue
                      ? AppTheme.success.withValues(alpha: .5)
                      : AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? ctrl.text.trim() : hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Map',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl, IconData icon,
      String hint,
      {bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, String value, List<String> labels,
      List<String> values, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.directions_car, color: AppTheme.primary)),
          items: List.generate(
            values.length,
            (i) => DropdownMenuItem(
                value: values[i], child: Text(labels[i])),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dateTimeTile() => InkWell(
        onTap: _pickDateTime,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup date & time',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      _pickupTime == null
                          ? 'Abhi book karo (1 ghante me)'
                          : _fmtDateTime(_pickupTime!),
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      );

  Widget _bidNote() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF6A1B9A).withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.gavel, color: Color(0xFF6A1B9A)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bid me fare pehle se fix nahi hota. Driver tumhari request dekh ke apna rate bhejenge.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );

  Widget _fareSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _loadingFare ? null : _getFare,
              icon: _loadingFare
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.currency_rupee),
              label:
                  Text(_loadingFare ? 'Fare nikal rahe hain...' : 'Get Fare'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_fare != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.success.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Fare',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '₹${_fare!['totalFare']}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fare!['breakdown']?.toString() ?? '',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
}
