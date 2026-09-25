import "dart:convert";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:http/http.dart" as http;
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class PostRequirementScreen extends StatefulWidget {
  const PostRequirementScreen({super.key});
  @override State<PostRequirementScreen> createState() => _PostRequirementScreenState();
}

class _PostRequirementScreenState extends State<PostRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _paxCtrl = TextEditingController(text: "2");
  final _budgetCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _vehicle = "sedan";
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _paxCtrl.dispose();
    _budgetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Date aur time chuno"),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/requirements"),
        headers: await _headers(),
        body: jsonEncode({
          "pickup": {"address": _fromCtrl.text.trim()},
          "drop": {"address": _toCtrl.text.trim()},
          "date":
              "${_date!.year}-${_date!.month.toString().padLeft(2, "0")}-${_date!.day.toString().padLeft(2, "0")}",
          "time":
              "${_time!.hour.toString().padLeft(2, "0")}:${_time!.minute.toString().padLeft(2, "0")}",
          "vehicleType": _vehicle,
          "passengers": int.tryParse(_paxCtrl.text.trim()) ?? 1,
          if (_budgetCtrl.text.trim().isNotEmpty)
            "budget": double.tryParse(_budgetCtrl.text.trim()) ?? 0,
          "notes": _notesCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      final body = jsonDecode(res.body);
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          body["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Requirement post ho gayi! Dusre drivers dekh payenge."),
          backgroundColor: AppTheme.success,
        ));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((body["message"] ?? "Post nahi ho payi").toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
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
          title: const Text("Post Requirement",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Kaisi trip chahiye?",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      "Apni requirement post karo — sirf drivers dekh payenge.",
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fromCtrl,
                        decoration: const InputDecoration(
                          labelText: "Pickup",
                          hintText: "Ahmedabad",
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? "Pickup likho"
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _toCtrl,
                        decoration: const InputDecoration(
                          labelText: "Drop",
                          hintText: "Vadodara",
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? "Drop likho"
                                : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppTheme.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                              _date == null
                                  ? "Date"
                                  : "${_date!.day}/${_date!.month}/${_date!.year}",
                              style: TextStyle(
                                  fontSize: 15,
                                  color: _date == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary),
                            )),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: AppTheme.border),
                          ),
                          child: Row(children: [
                            const Icon(Icons.schedule,
                                color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                              _time == null
                                  ? "Time"
                                  : _time!.format(context),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: _time == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary),
                            )),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _vehicle,
                        decoration: const InputDecoration(
                          labelText: "Gaadi",
                          prefixIcon:
                              Icon(Icons.directions_car_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "hatchback", child: Text("Hatchback")),
                          DropdownMenuItem(
                              value: "sedan", child: Text("Sedan")),
                          DropdownMenuItem(
                              value: "suv", child: Text("SUV")),
                          DropdownMenuItem(
                              value: "innova", child: Text("Innova")),
                        ],
                        onChanged: (v) =>
                            setState(() => _vehicle = v ?? "sedan"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _paxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Passengers",
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? "");
                          return (n == null || n < 1)
                              ? "1+ likho"
                              : null;
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Budget (₹) — optional",
                      hintText: "e.g. 2000",
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Extra notes — optional",
                      hintText: "e.g. AC chahiye, 2 suitcase",
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14)),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text("Post Karo",
                            style: TextStyle(fontSize: 16)),
                  ),
                ]),
          ),
        ),
      );
}
