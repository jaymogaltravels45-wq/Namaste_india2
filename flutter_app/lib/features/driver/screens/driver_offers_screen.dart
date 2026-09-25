import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverOffersScreen extends StatefulWidget {
  final String bookingId;
  const DriverOffersScreen({super.key, required this.bookingId});
  @override State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _booking;
  List<Map<String, dynamic>> _bids = [];
  // bidKey -> "accepted" | "rejected"
  final Map<String, String> _decisions = {};

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
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final b = body is Map ? (body["booking"] ?? body["data"] ?? body) : null;
        final map = b == null ? null : Map<String, dynamic>.from(b as Map);
        final raw = (map?["bids"] ?? []) as List;
        setState(() {
          _booking = map;
          _bids = raw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      } else {
        setState(
            () { _error = "Offers load nahi hui (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  String _bidKey(int i) => "bid_$i";

  void _decide(int i, bool accept) {
    final key = _bidKey(i);
    setState(() {
      if (accept) {
        // Ek accept hote hi baaki auto-reject
        for (var j = 0; j < _bids.length; j++) {
          _decisions[_bidKey(j)] = j == i ? "accepted" : "rejected";
        }
      } else {
        _decisions[key] = "rejected";
      }
    });
    final amount = _bids[i]["amount"]?.toString() ?? "";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(accept
          ? "Rs.$amount wali offer accept kar li!"
          : "Offer reject kar di"),
      backgroundColor: accept ? AppTheme.success : AppTheme.textSecondary,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Offers",
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
                : _body(),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_offer_outlined,
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

  Widget _body() {
    final b = _booking;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (b != null) _tripSummary(b),
        const SizedBox(height: 16),
        const Text("Mili hui offers",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_bids.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text("Abhi koi offer nahi aayi",
                      style:
                          TextStyle(color: AppTheme.textSecondary))),
            ),
          )
        else
          ..._bids.asMap().entries.map((e) => _bidCard(e.key, e.value)),
      ],
    );
  }

  Widget _tripSummary(Map b) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.route, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              "${_addr(b["pickup"])} → ${_addr(b["drop"])}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            )),
            Text("Rs.${b["estimatedFare"] ?? b["finalFare"] ?? "—"}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success)),
          ]),
        ),
      );

  Widget _bidCard(int i, Map<String, dynamic> bid) {
    final key = _bidKey(i);
    final decision = _decisions[key] ?? (bid["status"] ?? "pending").toString();
    final driver = bid["driverId"];
    final driverName = driver is Map
        ? (driver["name"] ?? "Driver").toString()
        : "Driver ${i + 1}";
    final amount = bid["amount"]?.toString() ?? "—";
    final decided = decision == "accepted" || decision == "rejected";

    Color chipColor;
    String chipLabel;
    if (decision == "accepted") {
      chipColor = AppTheme.success;
      chipLabel = "ACCEPTED";
    } else if (decision == "rejected") {
      chipColor = AppTheme.error;
      chipLabel = "REJECTED";
    } else {
      chipColor = AppTheme.warning;
      chipLabel = "PENDING";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: decision == "accepted"
                ? AppTheme.success
                : AppTheme.border,
            width: decision == "accepted" ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            const CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  Text(driverName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(_fmtDate(bid["createdAt"]),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ])),
            Text("Rs.$amount",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(chipLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: chipColor)),
            ),
          ]),
          if (!decided) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => _decide(i, false),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(
                              color: AppTheme.error)),
                      child: const Text("Reject"))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _decide(i, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white),
                      child: const Text("Accept"))),
            ]),
          ],
        ]),
      ),
    );
  }

  String _addr(dynamic p) {
    if (p == null) return "—";
    if (p is Map) return (p["address"] ?? "—").toString();
    return p.toString();
  }

  String _fmtDate(dynamic v) {
    if (v == null) return "";
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, "0")}";
    } catch (_) {
      return "";
    }
  }
}
