import "dart:convert";
import "dart:io";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../../../core/config/app_config.dart";
import "../../../core/theme/app_theme.dart";

class DriverKycScreen extends StatefulWidget {
  const DriverKycScreen({super.key});
  @override State<DriverKycScreen> createState() => _DriverKycScreenState();
}

class _DriverKycScreenState extends State<DriverKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  String _vehicleModel = "Sedan";

  File? _licensePhoto;
  File? _rcPhoto;
  bool _submitted = false;
  bool _saving = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _vehicleNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isLicense) async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera se lo"),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Gallery se chuno"),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (src == null) return;
    final x = await _picker.pickImage(source: src, imageQuality: 80);
    if (x == null) return;
    setState(() {
      if (isLicense) {
        _licensePhoto = File(x.path);
      } else {
        _rcPhoto = File(x.path);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licensePhoto == null || _rcPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Dono documents ki photo lagao"),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final res = await http.post(
        Uri.parse("${AppConfig.apiBaseUrl}/drivers/register"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": _nameCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "vehicleType": _vehicleModel.toLowerCase(),
          "vehicleNumber": _vehicleNoCtrl.text.trim(),
          "vehicleModel": _vehicleModel,
          "licenseNumber": _licenseCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body["success"] == true) {
        setState(() { _saving = false; _submitted = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("KYC submit ho gaya! Review me hai."),
          backgroundColor: AppTheme.success,
        ));
      } else if (res.statusCode == 409) {
        // Already registered — treat as submitted.
        setState(() { _saving = false; _submitted = true; });
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text((body["message"] ?? "Submit nahi hua").toString()),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Network error — phir try karo"),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Driver KYC",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: _submitted ? _reviewState() : _form(),
      );

  Widget _form() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Apne documents verify karwao",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                    "KYC approve hone ke baad hi bookings milengi.",
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Poora Naam",
                    hintText: "Rahul Sharma",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? "Apna naam likho"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                    hintText: "9876543210",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final d = (v ?? "").replaceAll(RegExp(r"\D"), "");
                    final n = d.length == 12 && d.startsWith("91") ? d.substring(2) : d;
                    return n.length == 10 ? null : "Sahi 10-digit number likho";
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _licenseCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "Driving License Number",
                    hintText: "GJ0120230001234",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().length < 8)
                      ? "Sahi license number likho"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleNoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Number",
                    hintText: "GJ01AB1234",
                    prefixIcon:
                        Icon(Icons.directions_car_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? "Sahi vehicle number likho"
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _vehicleModel,
                  decoration: const InputDecoration(
                    labelText: "Vehicle Model",
                    prefixIcon: Icon(Icons.car_rental_outlined),
                  ),
                  items: const ["Hatchback", "Sedan", "SUV", "Innova"]
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _vehicleModel = v ?? "Sedan"),
                ),
                const SizedBox(height: 16),
                _docTile(
                  title: "Driving License Photo",
                  file: _licensePhoto,
                  onTap: () => _pick(true),
                ),
                const SizedBox(height: 12),
                _docTile(
                  title: "RC (Registration Certificate)",
                  file: _rcPhoto,
                  onTap: () => _pick(false),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Submit KYC",
                          style: TextStyle(fontSize: 16)),
                ),
              ]),
        ),
      );

  Widget _docTile(
      {required String title,
      required File? file,
      required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: file != null
                    ? AppTheme.success
                    : AppTheme.border,
                width: file != null ? 2 : 1),
          ),
          child: file != null
              ? Row(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                    child: Image.file(file,
                        width: 120, height: 120, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Row(children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.success, size: 16),
                          SizedBox(width: 4),
                          Text("Photo lag gayi",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.success)),
                        ]),
                        const SizedBox(height: 4),
                        const Text("Badalne ke liye tap karo",
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ])),
                ])
              : const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 36, color: AppTheme.textSecondary),
                    SizedBox(height: 8),
                    Text("Tap karke photo lagao",
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13)),
                  ]),
                ),
        ),
      );

  Widget _reviewState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top,
                  size: 56, color: AppTheme.warning),
            ),
            const SizedBox(height: 20),
            const Text("KYC Review Me Hai",
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Hamari team aapke documents check kar rahi hai. Aam taur pe 24 ghante me approve ho jata hai.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border)),
              child: Text("License: ${_licenseCtrl.text}",
                  style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => setState(() => _submitted = false),
              icon: const Icon(Icons.edit),
              label: const Text("Details edit karo"),
            ),
          ]),
        ),
      );
}
