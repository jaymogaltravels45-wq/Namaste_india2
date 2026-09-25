import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverRequirementsScreen extends StatefulWidget {
  const DriverRequirementsScreen({super.key});
  @override
  State<DriverRequirementsScreen> createState() =>
      _DriverRequirementsScreenState();
}

class _DriverRequirementsScreenState extends State<DriverRequirementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<dynamic> _available = [];
  List<dynamic> _mine = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<List<dynamic>> _fetch(String path) async {
    final res = await http.get(
      Uri.parse("${AppConfig.apiBaseUrl}$path"),
      headers: await _headers(),
    );
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body);
    if (body["success"] != true) return [];
    return (body["requirements"] as List?) ?? [];
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await _fetch("/requirements");
      final m = await _fetch("/requirements/my");
      if (!mounted) return;
      setState(() {
        _available = a;
        _mine = m;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String id) async {
    final amtCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Offer Bhejo"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: amtCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Tumhara rate (₹)",
              prefixIcon:
                  Icon(Icons.currency_rupee, color: AppTheme.primary),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: msgCtrl,
            decoration: const InputDecoration(
              labelText: "Message (optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Bhejo")),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amtCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Sahi amount daalo"),
          backgroundColor: AppTheme.error,
        ));
      }
      return;
    }
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/requirements/$id/respond"),
        headers: await _headers(),
        body: jsonEncode(
            {"amount": amount, "message": msgCtrl.text.trim()}),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text((body["success"] == true)
            ? "Offer bhej di!"
            : (body["message"] ?? "Offer nahi bheji gayi").toString()),
        backgroundColor: (body["success"] == true)
            ? AppTheme.success
            : AppTheme.error,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Network error"),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _closeReq(String id) async {
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/requirements/$id/close"),
        headers: await _headers(),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Requirement close ho gayi"),
          backgroundColor: AppTheme.success,
        ));
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Driver Requirements",
              style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: "Available"),
              Tab(text: "Meri Posts"),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tab,
                children: [
                  _list(_available, false),
                  _list(_mine, true),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context
              .push("/driver/requirements/post")
              .then((_) => _load()),
          icon: const Icon(Icons.add),
          label: const Text("Post Requirement"),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
      );

  Widget _list(List<dynamic> items, bool mine) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.post_add_outlined,
                size: 72, color: AppTheme.border),
            const SizedBox(height: 12),
            Text(
                mine
                    ? "Tumne koi requirement post nahi ki"
                    : "Abhi koi requirement nahi hai",
                style:
                    const TextStyle(color: AppTheme.textSecondary)),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) =>
            _reqCard(Map<String, dynamic>.from(items[i] as Map), mine),
      ),
    );
  }

  Widget _reqCard(Map<String, dynamic> r, bool mine) {
    final id = r["_id"].toString();
    final status = (r["status"] ?? "open").toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                  "${_addr(r["pickup"])} → ${_addr(r["drop"])}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (status == "open"
                        ? AppTheme.success
                        : AppTheme.textSecondary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: status == "open"
                          ? AppTheme.success
                          : AppTheme.textSecondary)),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _chip(Icons.calendar_today, "${r["date"] ?? ""}"),
            _chip(Icons.schedule, "${r["time"] ?? ""}"),
            _chip(Icons.directions_car,
                "${r["vehicleType"] ?? ""} · ${r["passengers"] ?? 1} pax"),
            if (r["budget"] != null)
              _chip(Icons.currency_rupee, "Budget ₹${r["budget"]}"),
          ]),
          if ((r["notes"] ?? "").toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r["notes"].toString(),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 10),
          if (!mine && status == "open")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _respond(id),
                icon: const Icon(Icons.send, size: 18),
                label: const Text("Offer Bhejo"),
              ),
            ),
          if (mine && status == "open")
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _closeReq(id),
                icon: const Icon(Icons.close, size: 18),
                label: const Text("Close Karo"),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _chip(IconData i, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(t,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );

  String _addr(dynamic p) {
    if (p is Map) return (p["address"] ?? "—").toString();
    return (p ?? "—").toString();
  }
}
