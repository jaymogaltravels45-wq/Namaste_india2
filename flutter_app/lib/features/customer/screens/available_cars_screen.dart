import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "../../../core/config/app_config.dart";
import "../../../core/widgets/neumorphic.dart";

/// P23 — Available Cars & Drivers. Online verified drivers, server se.
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

  String _label(String v) {
    switch (v) {
      case 'all':
        return 'All';
      case 'hatchback':
        return 'Hatchback';
      case 'sedan':
        return 'Sedan';
      case 'suv':
        return 'SUV';
      case 'innova':
        return 'Innova';
      default:
        return v;
    }
  }

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
        final q = _query.toLowerCase();
        final hay =
            "${d["name"]} ${d["vehicleModel"]} ${d["vehicleType"]}".toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeuHeader(
                title: 'Available Cars',
                subtitle: 'Abhi online drivers',
              ),
              const SizedBox(height: 16),
              NeuTextField(
                controller: _searchCtrl,
                hint: 'Search cars or drivers…',
                icon: Icons.search_rounded,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final sel = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient:
                              sel ? NeuColors.accentGradient : null,
                          color: sel ? null : NeuColors.card,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: sel
                              ? NeuShadows.accentButton()
                              : NeuShadows.raised(blur: 10, offset: 4),
                        ),
                        child: Center(
                          child: Text(
                            _label(f),
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : NeuColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _body()),
            ],
          ),
        ),
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
                color: NeuColors.card,
                shape: BoxShape.circle,
                boxShadow: NeuShadows.raised(),
              ),
              child: const Icon(Icons.drive_eta_rounded,
                  size: 36, color: NeuColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text('Abhi koi driver online nahi',
                style: TextStyle(
                    color: NeuColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Thodi der baad dobara dekho.',
                style: TextStyle(color: NeuColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: NeuButton(
                  label: 'Refresh', onPressed: _load),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
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
    final title = model.isNotEmpty ? model : _label(vt);
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gaadi visual
          NeuInset(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Icon(Icons.directions_car_rounded,
                  size: 64, color: NeuColors.textDark.withValues(alpha: 0.75)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: NeuColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      '${_label(vt)} • $name',
                      style: const TextStyle(
                          color: NeuColors.textMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: NeuColors.accent),
                        const SizedBox(width: 3),
                        Text(rating,
                            style: const TextStyle(
                                color: NeuColors.textDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5)),
                        const SizedBox(width: 8),
                        Text('• $trips trips',
                            style: const TextStyle(
                                color: NeuColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: NeuColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: NeuColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('Online',
                            style: TextStyle(
                                color: NeuColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rate != null)
                    Text('₹$rate/km',
                        style: const TextStyle(
                            color: NeuColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          NeuButton(
            label: 'Hire',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/customer/booking',
                extra: {'type': 'outstation', 'vehicleType': vt}),
          ),
        ],
      ),
    );
  }
}
