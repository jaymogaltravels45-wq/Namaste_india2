import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverBidDetailScreen extends StatefulWidget {
  final String bookingId;
  const DriverBidDetailScreen({super.key, required this.bookingId});
  @override State<DriverBidDetailScreen> createState() => _DriverBidDetailScreenState();
}

class _DriverBidDetailScreenState extends State<DriverBidDetailScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _booking;
  final _bidCtrl = TextEditingController();
  final _bidMsgCtrl = TextEditingController();
  double? _myBidAmount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    _bidMsgCtrl.dispose();
    super.dispose();
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
        setState(() {
          _booking = b == null ? null : Map<String, dynamic>.from(b as Map);
          _loading = false;
        });
      } else {
        setState(() { _error = "Booking nahi mili (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}/accept"),
        headers: await _headers(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Booking accept ho gayi!"),
          backgroundColor: AppTheme.success,
        ));
        context.go("/driver/my-booking/${widget.bookingId}");
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
      setState(() => _busy = false);
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

  Future<void> _sendBid() async {
    final amount = double.tryParse(_bidCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Sahi bid amount daalo"),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse(
            "${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}/bids"),
        headers: await _headers(),
        body: jsonEncode(
            {"amount": amount, "message": _bidMsgCtrl.text.trim()}),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body["success"] == true) {
        setState(() => _myBidAmount = amount);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bid bhej di! Customer accept karega to notify hoga."),
          backgroundColor: AppTheme.success,
        ));
      } else if (res.statusCode == 403) {
        _showNegativeWalletDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              (body["message"] ?? "Bid nahi bheji gayi").toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Network error"),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  void _reject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request reject kar di")),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Booking Detail",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null || _booking == null
                ? _errorView()
                : _detail(),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error ?? "Kuch gadbad hui"),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry")),
          ]),
        ),
      );

  Widget _detail() {
    final b = _booking!;
    final isBidOpen = (b["status"] ?? "").toString() == "open_for_bids";
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _routeCard(b),
        const SizedBox(height: 12),
        _infoCard(b),
        const SizedBox(height: 12),
        _fareCard(b),
        const SizedBox(height: 20),
        if (isBidOpen) _bidCard(b) else _acceptRow(),
      ]),
    );
  }

  Widget _bidCard(Map b) {
    final customerBid = b["customerBid"] ?? b["estimatedFare"] ?? "—";
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.gavel, color: Color(0xFF6A1B9A)),
              const SizedBox(width: 8),
              const Text("Bid Booking",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Customer bid: Rs.$customerBid",
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A1B9A),
                        fontSize: 12)),
              ),
            ]),
            if (_myBidAmount != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                    "Tumhari bid: Rs.${_myBidAmount!.toStringAsFixed(0)} — customer ke accept ka wait karo",
                    style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _bidCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Tumhara rate (₹)",
                hintText: "e.g. 1400",
                prefixIcon:
                    Icon(Icons.currency_rupee, color: AppTheme.primary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bidMsgCtrl,
              decoration: const InputDecoration(
                labelText: "Message (optional)",
                hintText: "e.g. Sedan, AC, experienced driver",
                prefixIcon: Icon(Icons.message, color: AppTheme.primary),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _busy ? null : _sendBid,
              icon: const Icon(Icons.send),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_myBidAmount == null ? "Bid Bhejo" : "Bid Update Karo",
                        style: const TextStyle(fontSize: 16)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acceptRow() => Row(children: [
        Expanded(
            child: OutlinedButton(
                onPressed: _busy ? null : _reject,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text("Reject"))),
        const SizedBox(width: 12),
        Expanded(
            child: ElevatedButton(
                onPressed: _busy ? null : _accept,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text("Accept Booking"))),
      ]);

  Widget _routeCard(Map b) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _routeRow(Icons.my_location, AppTheme.success, "Pickup",
                _addr(b["pickup"])),
            const Padding(
              padding: EdgeInsets.only(left: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 22,
                  child: VerticalDivider(thickness: 2, color: AppTheme.border),
                ),
              ),
            ),
            _routeRow(Icons.location_on, AppTheme.error, "Drop",
                _addr(b["drop"])),
          ]),
        ),
      );

  Widget _routeRow(IconData icon, Color color, String label, String value) =>
      Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ])),
      ]);

  Widget _infoCard(Map b) => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _infoRow("Booking No",
                (b["bookingNumber"] ?? widget.bookingId).toString()),
            _infoRow("Type", (b["bookingType"] ?? "—").toString()),
            _infoRow("Vehicle", (b["vehicleType"] ?? "—").toString()),
            _infoRow("Distance", "${b["distanceKm"] ?? "—"} km"),
            _infoRow("Pickup Time", _timeOf(b), highlight: true),
            _infoRow("Status", (b["status"] ?? "pending").toString()),
            if ((b["notes"] ?? "").toString().isNotEmpty)
              _infoRow("Notes", b["notes"].toString()),
          ]),
        ),
      );

  Widget _infoRow(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: highlight
                              ? AppTheme.primary
                              : AppTheme.textPrimary))),
            ]),
      );

  Widget _fareCard(Map b) {
    final fare = b["estimatedFare"] ?? b["finalFare"] ?? "—";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFF0D47A1),
          Color(0xFF1976D2),
        ]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("Estimated Fare",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 4),
              Text("Customer se ye amount milega",
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
        Text("Rs.$fare",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

String _addr(dynamic p) {
  if (p == null) return "—";
  if (p is Map) return (p["address"] ?? "—").toString();
  return p.toString();
}

// TIME BUG FIX: pickup_time hamesha server se dikhao
String _timeOf(Map m) {
  final t = m["pickupTime"] ?? m["pickup_time"];
  if (t == null || t.toString().isEmpty) return "N/A";
  try {
    final dt = DateTime.parse(t.toString()).toLocal();
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ap = dt.hour < 12 ? "AM" : "PM";
    return "$h12:${dt.minute.toString().padLeft(2, "0")} $ap · ${dt.day}/${dt.month}/${dt.year}";
  } catch (_) {
    return t.toString();
  }
}
