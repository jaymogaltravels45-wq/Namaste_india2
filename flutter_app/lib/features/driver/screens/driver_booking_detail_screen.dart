import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const DriverBookingDetailScreen({super.key, required this.bookingId});
  @override
  State<DriverBookingDetailScreen> createState() =>
      _DriverBookingDetailScreenState();
}

class _DriverBookingDetailScreenState extends State<DriverBookingDetailScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rideOtpCtrl.dispose();
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
        setState(
            () { _error = "Booking not found (code ${res.statusCode})"; _loading = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = "Network error"; _loading = false; });
    }
  }

  Future<void> _tripAction(String action, {String? otp}) async {
    // action: "arrived" | "verify-start" | "start" | "complete"
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/bookings/${widget.bookingId}/$action"),
        headers: await _headers(),
        body: otp != null ? jsonEncode({"otp": otp}) : null,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && (body["success"] ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(switch (action) {
            "arrived" => "Inform customer — ask for OTP!",
            "verify-start" => "Trip started! Drive safe.",
            _ => "Trip complete! Collect payment.",
          }),
          backgroundColor: AppTheme.success,
        ));
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              (body["message"] ?? "Action failed (code ${res.statusCode})")
                  .toString()),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("My Booking",
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
            Text(_error ?? "Something went wrong"),
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
    final status = (b["status"] ?? "pending").toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _statusBanner(status),
        const SizedBox(height: 12),
        _routeCard(b),
        const SizedBox(height: 12),
        _customerCard(b),
        const SizedBox(height: 12),
        if (status == "arrived") _rideOtpEntryCard(),
        if (status == "arrived") const SizedBox(height: 12),
        _fareCard(b),
        const SizedBox(height: 20),
        _actionButton(status),
      ]),
    );
  }

  final _rideOtpCtrl = TextEditingController();

  Widget _rideOtpEntryCard() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: const Color(0xFFFFF8E1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open,
                        color: AppTheme.warning, size: 18),
                    SizedBox(width: 6),
                    Text("Ride Start OTP",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning)),
                  ]),
              const SizedBox(height: 6),
              const Text(
                  "Enter the 4-digit OTP received from customer",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              TextField(
                controller: _rideOtpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: "••••",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _statusBanner(String status) {
    Color c;
    String label;
    switch (status) {
      case "confirmed":
        c = AppTheme.primary;
        label = "Confirmed — head to pickup point";
        break;
      case "driver_assigned":
        c = AppTheme.primary;
        label = "Assigned — wait for customer";
        break;
      case "arrived":
        c = AppTheme.warning;
        label = "Arrived — collect OTP from customer";
        break;
      case "ongoing":
      case "started":
        c = AppTheme.warning;
        label = "Trip in progress";
        break;
      case "completed":
        c = AppTheme.success;
        label = "Trip completed";
        break;
      case "cancelled":
        c = AppTheme.error;
        label = "Booking cancelled";
        break;
      default:
        c = AppTheme.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.4))),
      child: Row(children: [
        Icon(Icons.info_outline, color: c, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: c, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

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
            const Divider(height: 24),
            Row(children: [
              const Icon(Icons.schedule,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              const Text("Pickup Time: ",
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text(_timeOf(b),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ]),
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

  Widget _customerCard(Map b) {
    final c = b["customer"];
    String name = "Customer";
    String phone = "—";
    if (c is Map) {
      name = (c["name"] ?? "Customer").toString();
      phone = (c["phone"] ?? "—").toString();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(phone,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ])),
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.success),
            tooltip: "Call customer",
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Calling $phone...")),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fareCard(Map b) {
    final fare = b["finalFare"] ?? b["estimatedFare"] ?? "—";
    final method = (b["paymentMethod"] ?? "cash").toString().toUpperCase();
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
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text("Fare",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text("Payment: $method",
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ])),
        Text("Rs.$fare",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _actionButton(String status) {
    if (status == "completed") {
      final rating = _booking!["rating"];
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 8),
              Text(
                  rating != null
                      ? "Complete · Rating: $rating★"
                      : "Trip complete — payment collected?",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success)),
            ]),
      );
    }
    if (status == "cancelled") return const SizedBox.shrink();

    String label;
    IconData icon;
    Color color;
    String action;
    if (status == "confirmed" || status == "driver_assigned" ||
        status == "pending") {
      label = "Mark as Arrived";
      icon = Icons.location_on;
      color = AppTheme.warning;
      action = "arrived";
    } else if (status == "arrived") {
      label = "OTP Verify & Start Trip";
      icon = Icons.play_arrow;
      color = AppTheme.primary;
      action = "verify-start";
    } else {
      // ongoing / started
      label = "Complete Trip";
      icon = Icons.flag;
      color = AppTheme.success;
      action = "complete";
    }
    return ElevatedButton.icon(
      onPressed: _busy
          ? null
          : () {
              if (action == "verify-start") {
                final otp = _rideOtpCtrl.text.trim();
                if (otp.length != 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Enter 4-digit OTP"),
                          backgroundColor: AppTheme.error));
                  return;
                }
                _tripAction(action, otp: otp);
              } else {
                _tripAction(action);
              }
            },
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
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
