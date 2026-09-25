import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../core/theme/app_theme.dart";
import "../../../core/widgets/premium.dart";

// KEY RULE: Negative balance -> block bookings
// TIME BUG FIX: Always display pickup_time from server
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _State();
}

class _State extends State<DriverHomeScreen> {
  double _balance = 150.0; // TODO: fetch from API
  bool _online = false;
  double _todayEarnings = 2450.0; // TODO: fetch from API
  int _todayTrips = 6; // TODO: fetch from API
  List<Map<String, dynamic>> _requests = [];

  bool get _canBook => _balance >= 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // TODO: Replace with real API: GET /api/drivers/wallet
    setState(() {
      if (_canBook) {
        _requests = [
          {
            "id": "BK001",
            "from": "Ahmedabad",
            "to": "Vadodara",
            "dist": "110 KM",
            "amt": "Rs.1,620",
            "vehicle": "Sedan",
            "pickup_time": "10:30 AM", // TIME BUG FIX: from server DB
            "type": "outstation",
          }
        ];
      }
    });
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            _hero(ctx),
            if (!_canBook) _negativeBanner(),
            Expanded(
              child: _canBook && _requests.isNotEmpty
                  ? _list()
                  : _emptyView(),
            ),
          ],
        ),
      );

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
                          onTap: () => ctx.go("/driver/wallet"),
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
                              onChanged: _canBook
                                  ? (v) =>
                                      setState(() => _online = v)
                                  : null,
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
                            '4.8',
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
              onTap: () => context.go("/driver/add-money"),
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

  Widget _list() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          const SectionTitle(title: 'Nayi Requests'),
          const SizedBox(height: 10),
          ..._requests.asMap().entries.map(
                (e) => Entrance(
                  delayMs: e.key * 120,
                  child: _RequestCard(
                    data: e.value,
                    onAccept: () => context.go(
                        "/driver/my-booking/${e.value["id"]}"),
                    onDecline: () =>
                        setState(() => _requests.removeAt(e.key)),
                  ),
                ),
              ),
        ],
      );

  Widget _emptyView() => PremiumEmpty(
        icon: _online
            ? Icons.hourglass_empty_rounded
            : Icons.power_settings_new_rounded,
        title: _online ? 'Nayi request ka intezaar' : 'Tum offline ho',
        subtitle: _online
            ? 'Jaise hi koi booking aayegi, yahin dikhegi.'
            : 'Online jao taaki trip requests milna shuru hon.',
        ctaLabel: _online ? null : 'Online Jao',
        onCta: _online
            ? null
            : (_canBook ? () => setState(() => _online = true) : null),
      );
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onAccept, onDecline;
  const _RequestCard(
      {required this.data, required this.onAccept, required this.onDecline});

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
                    onPressed: onAccept,
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
                    child: const Text('Accept',
                        style: TextStyle(
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
