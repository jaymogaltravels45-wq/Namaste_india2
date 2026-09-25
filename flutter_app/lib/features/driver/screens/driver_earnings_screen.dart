import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/driver/my"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body is Map ? (body["bookings"] ?? body["data"] ?? []) : [];
        final all = (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _trips = all
              .where((b) => (b["status"] ?? "").toString() == "completed")
              .toList();
          _loading = false;
        });
      } else {
        setState(
            () { _error = "Earnings load nahi hui (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  double _fareOf(Map b) {
    final f = b["finalFare"] ?? b["estimatedFare"] ?? 0;
    return (f is num) ? f.toDouble() : double.tryParse(f.toString()) ?? 0;
  }

  DateTime? _endOf(Map b) {
    final t = b["endTime"] ?? b["updatedAt"];
    if (t == null) return null;
    try {
      return DateTime.parse(t.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    double today = 0, week = 0, total = 0;
    for (final t in _trips) {
      final fare = _fareOf(t);
      total += fare;
      final end = _endOf(t);
      if (end != null) {
        if (end.year == now.year &&
            end.month == now.month &&
            end.day == now.day) {
          today += fare;
        }
        if (now.difference(end).inDays < 7) week += fare;
      }
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Earnings",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: "Refresh"),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _body(today, week, total),
                ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.trending_down,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry")),
          ]),
        ),
      );

  Widget _body(double today, double week, double total) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Text("Aaj ki kamai",
                  style:
                      TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text("Rs.${today.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _miniStat("Is hafte",
                        "Rs.${week.toStringAsFixed(0)}")),
                Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withOpacity(0.3)),
                Expanded(
                    child: _miniStat(
                        "Total", "Rs.${total.toStringAsFixed(0)}")),
                Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withOpacity(0.3)),
                Expanded(
                    child: _miniStat(
                        "Trips", "${_trips.length}")),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text("Trip-wise kamai",
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_trips.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text(
                        "Abhi koi complete trip nahi hai",
                        style: TextStyle(
                            color: AppTheme.textSecondary))),
              ),
            )
          else
            ..._trips.map(_tripTile),
        ],
      );

  Widget _miniStat(String label, String value) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ]);

  Widget _tripTile(Map<String, dynamic> t) {
    final end = _endOf(t);
    final when = end == null
        ? ""
        : "${end.day}/${end.month}/${end.year}";
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.12),
              shape: BoxShape.circle),
          child: const Icon(Icons.directions_car,
              color: AppTheme.success, size: 18),
        ),
        title: Text(
            "${_addr(t["pickup"])} → ${_addr(t["drop"])}",
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
            "${(t["vehicleType"] ?? "").toString()} · $when",
            style: const TextStyle(fontSize: 11)),
        trailing: Text("Rs.${_fareOf(t).toStringAsFixed(0)}",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.success,
                fontSize: 15)),
      ),
    );
  }

  String _addr(dynamic p) {
    if (p == null) return "—";
    if (p is Map) return (p["address"] ?? "—").toString();
    return p.toString();
  }
}
