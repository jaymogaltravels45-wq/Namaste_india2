import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

/// P23 (Travel edition) — Available Cars. Online verified drivers, live rates.
class AvailableCarsScreen extends StatefulWidget {
  const AvailableCarsScreen({super.key});
  @override
  State<AvailableCarsScreen> createState() => _AvailableCarsScreenState();
}

class _AvailableCarsScreenState extends State<AvailableCarsScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _drivers = [];
  Map<String, int> _perKm = {};
  String _filter = 'all';
  String _query = '';

  static const _filters = ['all', 'hatchback', 'sedan', 'suv', 'innova'];

  String _label(String v) => switch (v) {
        'all' => 'All',
        'hatchback' => 'Hatchback',
        'sedan' => 'Sedan',
        'suv' => 'SUV',
        'innova' => 'Innova',
        _ => v,
      };

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
    setState(() => _loading = true);
    try {
      final base = AppConfig.apiBaseUrl;
      final results = await Future.wait([
        http.get(Uri.parse("$base/drivers/online")),
        http.get(Uri.parse("$base/fare/rates")),
      ]);
      if (!mounted) return;
      var drivers = <Map<String, dynamic>>[];
      if (results[0].statusCode == 200) {
        final b = jsonDecode(results[0].body) as Map<String, dynamic>;
        drivers = ((b["drivers"] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      var perKm = <String, int>{};
      if (results[1].statusCode == 200) {
        final b = jsonDecode(results[1].body) as Map<String, dynamic>;
        final vr = b["vehicleRates"];
        if (vr is Map) {
          vr.forEach((k, v) {
            if (v is Map && v["perKm"] is num) {
              perKm[k.toString()] = (v["perKm"] as num).toInt();
            }
          });
        }
      }
      setState(() {
        _drivers = drivers;
        _perKm = perKm;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _shown {
    return _drivers.where((d) {
      if (_filter != 'all' && d["vehicleType"]?.toString() != _filter) {
        return false;
      }
      if (_query.isNotEmpty) {
        final hay =
            "${d["name"]} ${d["vehicleModel"]} ${d["vehicleType"]}".toLowerCase();
        if (!hay.contains(_query)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _header(context),
          _searchBar(),
          _filterChips(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.navy, AppTheme.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Cars',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text(
                      _loading
                          ? 'Finding drivers…'
                          : '${_drivers.length} online now',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.shadowSm,
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search cars or drivers',
            hintStyle:
                TextStyle(color: AppTheme.textTertiary, fontSize: 13.5),
            prefixIcon: Icon(Icons.search_rounded,
                color: AppTheme.textTertiary, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final sel = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.goldGradient : null,
                color: sel ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Center(
                child: Text(_label(f),
                    style: TextStyle(
                        color: sel ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    final list = _shown;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: AppTheme.shadowSm,
              ),
              child: const Icon(Icons.drive_eta_rounded,
                  size: 36, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            const Text('No drivers online',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Try again in a bit.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: 170,
              child: ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Refresh',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _carCard(list[i]),
      ),
    );
  }

  Widget _carCard(Map<String, dynamic> d) {
    final vt = d["vehicleType"]?.toString() ?? 'sedan';
    final model = (d["vehicleModel"]?.toString() ?? '').trim();
    final name = (d["name"]?.toString() ?? 'Driver').trim();
    final rating = (d["rating"] ?? 0).toString();
    final trips = d["totalTrips"] ?? 0;
    final rate = _perKm[vt];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_car_rounded,
                size: 32, color: AppTheme.primaryDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.isNotEmpty ? model : _label(vt),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text('${_label(vt)} • $name',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppTheme.goldDeep),
                    const SizedBox(width: 3),
                    Text(rating,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.textPrimary)),
                    Text(' • $trips trips',
                        style: const TextStyle(
                            color: AppTheme.textTertiary, fontSize: 11.5)),
                    if (rate != null)
                      Text(' • ₹$rate/km',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.go('/customer/booking',
                extra: {'type': 'outstation', 'vehicleType': vt}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 11),
              elevation: 0,
            ),
            child: const Text('Select',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
