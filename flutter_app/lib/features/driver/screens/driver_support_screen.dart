import "package:flutter/material.dart";
import "../../../core/theme/app_theme.dart";

class DriverSupportScreen extends StatefulWidget {
  const DriverSupportScreen({super.key});
  @override State<DriverSupportScreen> createState() => _DriverSupportScreenState();
}

class _DriverSupportScreenState extends State<DriverSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String _category = "Payment";
  bool _sent = false;

  static const _topics = [
    {
      "q": "Wallet me paise kaise add karun?",
      "a": "Wallet screen me 'Add Money' dabao, amount likho aur UPI se pay karo. Paise turant wallet me dikhenge."
    },
    {
      "q": "Booking accept kyun nahi ho rahi?",
      "a": "Agar wallet balance negative hai to bookings block ho jati hain. Pehle wallet me paise add karo, phir accept kar paoge."
    },
    {
      "q": "KYC kitne time me approve hota hai?",
      "a": "Aam taur pe 24 ghante ke andar. Documents saaf photo me hone chahiye — license aur RC dono."
    },
    {
      "q": "Customer ne payment nahi kiya to kya karun?",
      "a": "Trip complete karne ke baad 'Support' me issue raise karo. Hamari team 48 ghante me resolve karti hai."
    },
    {
      "q": "Subscription ke fayde kya hain?",
      "a": "Priority requests, zero commission period aur dedicated support. Subscription screen pe plans dekh sakte ho."
    },
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _submitIssue() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sent = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Issue raise ho gaya! Team jald contact karegi."),
      backgroundColor: AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Help & Support",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _contactCard(),
                const SizedBox(height: 20),
                const Text("Aksar puche jaane wale sawaal",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._topics.map((t) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(t["q"]!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 16),
                            child: Text(t["a"]!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color:
                                        AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                const Text("Issue raise karo",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _sent ? _sentCard() : _issueForm(),
              ]),
        ),
      );

  Widget _contactCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF0D47A1),
            Color(0xFF1976D2),
          ]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Text("Humse baat karo",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("24x7 driver support · Hindi/English",
              style:
                  TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text("Calling support: 1800-123-456...")),
                ),
                icon: const Icon(Icons.call),
                label: const Text("Call"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "WhatsApp chat khul raha hai...")),
                ),
                icon: const Icon(Icons.chat),
                label: const Text("Chat"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary),
              ),
            ),
          ]),
        ]),
      );

  Widget _issueForm() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  "Payment",
                  "Booking",
                  "KYC",
                  "App Problem",
                  "Other"
                ]
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? "Payment"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Problem likho",
                  hintText:
                      "Kya hua, kab hua — detail me likho",
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 10)
                        ? "Thoda detail me likho (10+ letters)"
                        : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitIssue,
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
                style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12)),
              ),
            ]),
          ),
        ),
      );

  Widget _sentCard() => Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: AppTheme.success.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Icon(Icons.check_circle,
                color: AppTheme.success, size: 48),
            const SizedBox(height: 12),
            Text("Issue mil gaya! ($_category)",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              "Ticket ID: NI-58213. Hamari team 24 ghante me contact karegi.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() {
                _sent = false;
                _descCtrl.clear();
              }),
              child: const Text("Ek aur issue likho"),
            ),
          ]),
        ),
      );
}
