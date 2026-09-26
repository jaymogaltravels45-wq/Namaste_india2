import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:geolocator/geolocator.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";
import "../../../core/widgets/premium.dart";
import '../../../core/routes/nav.dart';

// KEY RULE: Negative balance -> block bookings
// TIME BUG FIX: Always display pickup_time from server
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _State();
}

class _State extends State<DriverHomeScreen> {
  double _balance = 0;
  bool _online = false;
  bool _canBook = true;
  double _todayEarnings = 0;
  int _todayTrips = 0;
  String _rating = '—';
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error; // 'not_registered' | 'load_failed' | null
  bool _toggling = false;
  String? _acceptingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  String _msgOf(http.Response res, String fallback) {
    try {
      final b = jsonDecode(res.body);
      if (b is Map && b["message"] != null) return b["message"].toString();
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Wallet + profile + nayi requests + aaj ki kamai — sab asli server se.
  Future<void> _loadData() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await _headers();
      final base = AppConfig.apiBaseUrl;
      final results = await Future.wait([
        http.get(Uri.parse("$base/drivers/wallet"), headers: h),
        http.get(Uri.parse("$base/drivers/profile"), headers: h),
        http.get(Uri.parse("$base/bookings/available"), headers: h),
        http.get(Uri.parse("$base/bookings/driver/my"), headers: h),
      ]);
      if (!mounted) return;
      final walletRes = results[0];
      final profileRes = results[1];
      final availRes = results[2];
      final myRes = results[3];

      if (walletRes.statusCode == 404) {
        // Driver abhi register nahi hai -> KYC/register screen pe bhejo
        setState(() {
          _loading = false;
          _error = 'not_registered';
        });
        return;
      }
      if (walletRes.statusCode != 200) throw Exception('wallet ${walletRes.statusCode}');

      final w = jsonDecode(walletRes.body) as Map<String, dynamic>;
      final rawBal = w["balance"];
      final bal = rawBal is num ? rawBal.toDouble() : 0.0;
      final canBook = w["canAcceptBookings"] == true || bal >= 0;

      var online = false;
      var rating = '—';
      if (profileRes.statusCode == 200) {
        final p = jsonDecode(profileRes.body) as Map<String, dynamic>;
        final d = p["driver"] is Map ? Map<String, dynamic>.from(p["driver"]) : null;
        online = d?["isOnline"] == true;
        if (d?["rating"] != null) rating = d!["rating"].toString();
      }

      var reqs = <Map<String, dynamic>>[];
      if (availRes.statusCode == 200) {
        final a = jsonDecode(availRes.body) as Map<String, dynamic>;
        final raw = (a["bookings"] as List?) ?? [];
        reqs = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // Aaj ki kamai: aaj complete hui bookings ka jod
      var earn = 0.0;
      var trips = 0;
      if (myRes.statusCode == 200) {
        final m = jsonDecode(myRes.body) as Map<String, dynamic>;
        final raw = (m["bookings"] as List?) ?? [];
        final now = DateTime.now();
        for (final e in raw) {
          final b = Map<String, dynamic>.from(e as Map);
          if (b["status"]?.toString() != "completed") continue;
          DateTime? done;
          try {
            final t = (b["endTime"] ?? b["updatedAt"])?.toString();
            if (t != null) done = DateTime.parse(t).toLocal();
          } catch (_) {}
          if (done != null &&
              done.year == now.year &&
              done.month == now.month &&
              done.day == now.day) {
            trips++;
            final f = b["finalFare"] ?? b["estimatedFare"];
            if (f is num) earn += f.toDouble();
          }
        }
      }

      setState(() {
        _balance = bal;
        _canBook = canBook;
        _online = online;
        _rating = rating;
        _requests = reqs;
        _todayEarnings = earn;
        _todayTrips = trips;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'load_failed';
      });
    }
  }

  Future<void> _setOnline(bool v) async {
    if (_toggling) return;
    if (v && !_canBook) {
      _snack('Pehle wallet recharge karo', error: true);
      return;
    }
    setState(() => _toggling = true);
    try {
      final res = await http.patch(
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/status"),
        headers: await _headers(),
        body: jsonEncode({"isOnline": v}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _online = v;
          _toggling = false;
        });
        _snack(v ? 'Tum online ho — requests aayengi' : 'Tum offline ho');
        if (v) _loadData();
      } else {
        setState(() => _toggling = false);
        _snack(_msgOf(res, 'Status badal nahi paya'), error: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _toggling = false);
      _snack('Network error', error: true);
    }
  }

  Future<void> _acceptBooking(String id) async {
    if (_acceptingId != null) return;
    setState(() => _acceptingId = id);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/$id/accept"),
        headers: await _headers(),
      );
      if (!mounted) return;
      setState(() => _acceptingId = null);
      if (res.statusCode == 200) {
        _snack('Booking accept ho gayi!');
        Nav.push(context, "/driver/my-booking/$id");
      } else {
        _snack(_msgOf(res, 'Accept nahi ho payi'), error: true);
        _loadData(); // list refresh — shayad kisi aur ne le li
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _acceptingId = null);
      _snack('Network error', error: true);
    }
  }

  /// Server ki booking -> request card ka data
  Map<String, dynamic> _cardOf(Map<String, dynamic> b) {
    final pickup = b["pickup"] is Map ? Map<String, dynamic>.from(b["pickup"]) : {};
    final drop = b["drop"] is Map ? Map<String, dynamic>.from(b["drop"]) : {};
    final fare = b["estimatedFare"] ?? b["finalFare"] ?? 0;
    var time = 'N/A';
    final t = (b["pickupTimeIST"] ?? b["pickupTime"])?.toString() ?? '';
    if (t.isNotEmpty) time = t.length > 18 ? t.substring(0, 18) : t;
    return {
      "id": b["_id"]?.toString() ?? "",
      "from": (pickup["address"] ?? "").toString(),
      "to": (drop["address"] ?? "").toString(),
      "dist": "${b["distanceKm"] ?? 0} KM",
      "amt": "Rs.$fare",
      "vehicle": (b["vehicleType"] ?? "").toString(),
      "pickup_time": time,
      "status": (b["status"] ?? "").toString(),
    };
  }

  @override
  Widget build(BuildContext ctx) => DoubleTapToExit(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: Column(
            children: [
              _hero(ctx),
              if (!_canBook && !_loading) _negativeBanner(),
              Expanded(child: _bodyContent()),
            ],
          ),
        ),
      );

  Widget _bodyContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if (_error == 'not_registered') {
      // Driver ka record server pe nahi — KYC/register karwao
      return PremiumEmpty(
        icon: Icons.badge_rounded,
        title: 'Driver registration baaki hai',
        subtitle:
            'Requests pane se pehle apni gaadi aur license ki details poori karo.',
        ctaLabel: 'Registration Karo',
        onCta: () => Nav.push(context, '/driver/kyc'),
      );
    }
    if (_error == 'load_failed') {
      return PremiumEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Data load nahi hua',
        subtitle: 'Internet check karo aur dobara koshish karo.',
        ctaLabel: 'Dobara Koshish Karo',
        onCta: _loadData,
      );
    }
    if (_requests.isNotEmpty) return _list();
    return _emptyView();
  }

  Widget _hero(BuildContext ctx) => Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.rXl),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.10),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.shadowGold,
                          ),
                          child: const Icon(
                            Icons.drive_eta_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Namaste, Driver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Aaj ki kamai shuru karo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Nav.push(ctx, "/driver/notifications"),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Nav.push(ctx, "/driver/wallet"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    Colors.white.withOpacity(0.22),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 15,
                                  color: _canBook
                                      ? AppTheme.gold
                                      : AppTheme.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Rs.${_balance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: _canBook
                                        ? Colors.white
                                        : const Color(0xFFFFB4A8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Online toggle card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(AppTheme.rLg),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _online && _canBook
                                  ? AppTheme.success
                                  : Colors.white38,
                              boxShadow: _online && _canBook
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.success
                                            .withOpacity(0.8),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _online && _canBook
                                      ? 'Online — Requests ON'
                                      : 'Offline',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  _canBook
                                      ? 'Nayi trip requests yahin aayengi'
                                      : 'Wallet recharge karo',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 1.1,
                            child: Switch(
                              value: _online && _canBook,
                              onChanged: _toggling
                                  ? null
                                  : (_canBook ? (v) => _setOnline(v) : null),
                              activeColor: AppTheme.success,
                              activeTrackColor: AppTheme.success
                                  .withOpacity(0.4),
                              inactiveThumbColor: Colors.white70,
                              inactiveTrackColor:
                                  Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            Icons.currency_rupee_rounded,
                            'Rs.${_todayEarnings.toStringAsFixed(0)}',
                            "Aaj ki kamai",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            Icons.route_rounded,
                            '$_todayTrips',
                            'Aaj ke trips',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            Icons.star_rounded,
                            _rating,
                            'Rating',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _statCard(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _negativeBanner() => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD92D20), Color(0xFFB42318)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Wallet Rs.${_balance.toStringAsFixed(0)} — bookings blocked!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: () => Nav.push(context, "/driver/add-money"),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Add Money',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _list() => RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            const Entrance(delayMs: 0, child: _LiveMapCard()),
            const SizedBox(height: 14),
            const SectionTitle(title: 'Nayi Requests'),
            const SizedBox(height: 10),
            ..._requests.asMap().entries.map(
                  (e) => Entrance(
                    delayMs: e.key * 120,
                    child: _requestTile(e.key, e.value),
                  ),
                ),
          ],
        ),
      );

  Widget _requestTile(int index, Map<String, dynamic> booking) {
    final data = _cardOf(booking);
    final id = data["id"] as String;
    final isBidding = data["status"] == "open_for_bids";
    final accepting = _acceptingId == id;
    return _RequestCard(
      data: data,
      acceptLabel: isBidding ? 'Bid Lagao' : 'Accept',
      busy: accepting,
      onAccept: () {
        if (isBidding) {
          Nav.push(context, "/driver/bid/$id");
        } else {
          _acceptBooking(id);
        }
      },
      onDecline: () => setState(() => _requests.removeAt(index)),
    );
  }

  Widget _emptyView() => PremiumEmpty(
        icon: _online
            ? Icons.hourglass_empty_rounded
            : Icons.power_settings_new_rounded,
        title: _online ? 'Nayi request ka intezaar' : 'Tum offline ho',
        subtitle: _online
            ? 'Jaise hi koi booking aayegi, yahin dikhegi. Neeche kheench ke refresh bhi kar sakte ho.'
            : 'Online jao taaki trip requests milna shuru hon.',
        ctaLabel: _online ? 'Refresh Karo' : 'Online Jao',
        onCta: _online ? _loadData : (_canBook ? () => _setOnline(true) : null),
      );
}

/// Driver ki live location dikhane wala mini map card.
class _LiveMapCard extends StatefulWidget {
  const _LiveMapCard();

  @override
  State<_LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<_LiveMapCard> {
  final _mapCtrl = MapController();
  LatLng? _pos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _pos = LatLng(p.latitude, p.longitude);
        _loading = false;
      });
      _mapCtrl.move(_pos!, 14);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        boxShadow: AppTheme.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _pos ?? const LatLng(23.0225, 72.5714),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.namasteindia.app',
              ),
              if (_pos != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _pos!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 3),
                        boxShadow: AppTheme.shadowMd,
                      ),
                      child: const Icon(Icons.directions_car,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ]),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.white.withValues(alpha: .6),
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Meri live location',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: GestureDetector(
              onTap: _locate,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.shadowMd,
                ),
                child: const Icon(Icons.my_location,
                    color: AppTheme.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onDecline;
  final String acceptLabel;
  final bool busy;
  const _RequestCard({
    required this.data,
    required this.onAccept,
    required this.onDecline,
    this.acceptLabel = 'Accept',
    this.busy = false,
  });

  @override
  Widget build(BuildContext ctx) {
    // TIME BUG FIX: Always display pickup_time from server
    final time = (data["pickup_time"]?.toString().isNotEmpty == true)
        ? data["pickup_time"]
        : "N/A";
    return PremiumCard(
      shadows: AppTheme.shadowMd,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.error, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${data["from"] ?? ""} → ${data["to"] ?? ""}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Pill(
                text: time.toString(),
                color: AppTheme.primary,
                bg: AppTheme.infoSoft,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _meta(Icons.directions_car_rounded,
                  data["vehicle"]?.toString() ?? ""),
              const SizedBox(width: 14),
              _meta(Icons.route_rounded,
                  data["dist"]?.toString() ?? ""),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data["amt"]?.toString() ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(
                        color: AppTheme.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.rMd),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Decline',
                      style:
                          TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.successGradient,
                    borderRadius:
                        BorderRadius.circular(AppTheme.rMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: busy ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.rMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 13),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(acceptLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData i, String t) => Row(
        children: [
          Icon(i, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 4),
          Text(t,
              style: const TextStyle(
                  fontSize: 12.5, color: AppTheme.textSecondary)),
        ],
      );
}
