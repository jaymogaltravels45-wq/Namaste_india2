import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverNewRequestsScreen extends StatefulWidget {
  const DriverNewRequestsScreen({super.key});
  @override State<DriverNewRequestsScreen> createState() => _DriverNewRequestsScreenState();
}

class _DriverNewRequestsScreenState extends State<DriverNewRequestsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookings = [];
  final Set<String> _accepting = {};

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
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/available"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final raw = body is Map ? (body["bookings"] ?? body["data"] ?? []) : [];
        setState(() {
          _bookings = (raw as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      } else {
        setState(() { _error = "Server error: ${res.statusCode}"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error — pull karke retry karo."; _loading = false; });
    }
  }

  Future<void> _accept(String id) async {
    setState(() => _accepting.add(id));
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/$id/accept"),
        headers: await _headers(),
      );
      if (!mounted) return;
      setState(() => _accepting.remove(id));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Booking accept ho gayi!"),
          backgroundColor: AppTheme.success,
        ));
        context.go("/driver/my-booking/$id");
      } else if (res.statusCode == 403) {
        _showNegativeWalletDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Accept nahi hui (code ${res.statusCode})"),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _accepting.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Network error"),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  void _showNegativeWalletDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          SizedBox(width: 8),
          Text("Wallet Negative"),
        ]),
        content: const Text(
            "Aapka wallet balance negative hai. Pehle paise add karo, tabhi booking accept kar paoge."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Baad me")),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go("/driver/add-money");
              },
              child: const Text("Add Money")),
        ],
      ),
    );
  }

  void _decline(int index) {
    final removed = _bookings[index];
    setState(() => _bookings.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Request decline ki: ${_addr(removed["pickup"])}"),
      action: SnackBarAction(
        label: "Undo",
        onPressed: () => setState(() => _bookings.insert(index, removed)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("New Requests",
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
                    child: _bookings.isEmpty ? _emptyView() : _list(),
                  ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ]),
        ),
      );

  Widget _emptyView() => ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.hourglass_empty, size: 72, color: AppTheme.border),
          SizedBox(height: 12),
          Center(
              child: Text("Abhi koi nayi request nahi hai",
                  style: TextStyle(color: AppTheme.textSecondary))),
          SizedBox(height: 6),
          Center(
              child: Text("Online raho — request aate hi yahan dikhegi",
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        ],
      );

  Widget _list() => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (_, i) => _RequestCard(
          data: _bookings[i],
          accepting: _accepting.contains(_idOf(_bookings[i])),
          onTap: () => context.go("/driver/bid/${_idOf(_bookings[i])}"),
          onAccept: () => _accept(_idOf(_bookings[i])),
          onDecline: () => _decline(i),
        ),
      );
}

String _idOf(Map m) => (m["_id"] ?? m["id"] ?? "").toString();

String _addr(dynamic p) {
  if (p == null) return "—";
  if (p is Map) return (p["address"] ?? "—").toString();
  return p.toString();
}

String _fareOf(Map m) {
  final f = m["estimatedFare"] ?? m["finalFare"] ?? m["fare"];
  if (f == null) return "—";
  return "Rs.$f";
}

// TIME BUG FIX: pickup_time hamesha server se dikhao
String _timeOf(Map m) {
  final t = m["pickupTime"] ?? m["pickup_time"];
  if (t == null || t.toString().isEmpty) return "N/A";
  try {
    final dt = DateTime.parse(t.toString()).toLocal();
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ap = dt.hour < 12 ? "AM" : "PM";
    return "$h12:${dt.minute.toString().padLeft(2, "0")} $ap · ${dt.day}/${dt.month}";
  } catch (_) {
    return t.toString();
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool accepting;
  final VoidCallback onTap, onAccept, onDecline;
  const _RequestCard({
    required this.data,
    required this.accepting,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext ctx) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on, color: AppTheme.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(
                    "${_addr(data["pickup"])} → ${_addr(data["drop"])}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(_timeOf(data),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.directions_car,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text((data["vehicleType"] ?? data["vehicle"] ?? "—").toString(),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.route,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text("${data["distanceKm"] ?? data["dist"] ?? "—"} km",
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                        (data["bookingType"] ?? "outstation").toString(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success)),
                  ),
                  const Spacer(),
                  Text(_fareOf(data),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error)),
                          child: const Text("Decline"))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: accepting ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white),
                          child: accepting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text("Accept"))),
                ]),
              ],
            ),
          ),
        ),
      );
}
