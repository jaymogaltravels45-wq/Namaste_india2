import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "driver_requirements_screen.dart";
import "../../../core/theme/app_theme.dart";

class PostRequirementScreen extends StatefulWidget {
  const PostRequirementScreen({super.key});
  @override State<PostRequirementScreen> createState() => _PostRequirementScreenState();
}

class _PostRequirementScreenState extends State<PostRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  String _vehicle = "Sedan";
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Date chuno"),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _saving = true);
    final req = DriverRequirement(
      title: _titleCtrl.text.trim(),
      route: "${_fromCtrl.text.trim()} → ${_toCtrl.text.trim()}",
      vehicle: _vehicle,
      date: "${_date!.day}/${_date!.month}/${_date!.year}",
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      RequirementStore.add(req);
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Requirement post ho gayi!"),
        backgroundColor: AppTheme.success,
      ));
      context.pop();
    });
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
                      "Apni requirement post karo — customers dekh payenge.",
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      hintText: "Daily office pickup",
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Title likho"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fromCtrl,
                        decoration: const InputDecoration(
                          labelText: "From",
                          hintText: "Ahmedabad",
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? "From likho"
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _toCtrl,
                        decoration: const InputDecoration(
                          labelText: "To",
                          hintText: "Vadodara",
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? "To likho"
                                : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _vehicle,
                    decoration: const InputDecoration(
                      labelText: "Vehicle",
                      prefixIcon:
                          Icon(Icons.directions_car_outlined),
                    ),
                    items: const [
                      "Hatchback",
                      "Sedan",
                      "SUV",
                      "Innova"
                    ]
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _vehicle = v ?? "Sedan"),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                          _date == null
                              ? "Date chuno"
                              : "${_date!.day}/${_date!.month}/${_date!.year}",
                          style: TextStyle(
                              fontSize: 16,
                              color: _date == null
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary),
                        )),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.textSecondary),
                      ]),
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
