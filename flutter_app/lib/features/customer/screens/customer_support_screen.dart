import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _submitted = false;
  String _ticketId = '';

  static const _faqs = [
    {
      'q': 'Ride ka fare kaise calculate hota hai?',
      'a': 'Outstation me 100 km tak fixed rate hai, uske baad per-km charge lagta hai. Local me 4h/40km, 8h/80km aur 12h/120km ke fixed packages hain.'
    },
    {
      'q': 'Payment kaise karun?',
      'a': 'Ride khatam hone pe Cash de sakte ho ya company ke UPI ID pe pay kar sakte ho. Payment booking detail screen ke "Pay Now" button se hota hai.'
    },
    {
      'q': 'Ride OTP kya hai?',
      'a': 'Har booking pe ek 6-digit OTP banta hai. Ride shuru karne se pehle ye OTP driver ko batana hota hai — isse sahi driver verify hota hai.'
    },
    {
      'q': 'Driver nahi mil raha, kya karun?',
      'a': 'Booking "Pending" state me kuch der ruko. Agar der ho jaye to support ticket raise karo ya helpline pe call karo.'
    },
    {
      'q': 'Bid wali booking kaise kaam karti hai?',
      'a': 'Bid me tum request bhejte ho aur driver apna rate offer karte hain. Tumhe jo rate sahi lage, use accept kar lo.'
    },
  ];

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copy ho gaya'),
      backgroundColor: AppTheme.success,
    ));
  }

  void _submitTicket() {
    if (_subjectCtrl.text.trim().isEmpty ||
        _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Subject aur message dono likhiye'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    final id =
        'NI-T${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _submitted = true;
      _ticketId = id;
    });
    _subjectCtrl.clear();
    _messageCtrl.clear();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _contactCard(),
            const SizedBox(height: 16),
            const Text('Aksar pooche jaane wale sawaal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._faqs.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(f['q']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(f['a']!,
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            const Text('Ticket Raise Karo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _submitted ? _confirmationCard() : _ticketForm(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _contactCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Humse baat karo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Subah 8 se raat 10 tak, hafte ke 7 din',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            _contactRow(context, Icons.phone, '1800-123-4567'),
            const SizedBox(height: 8),
            _contactRow(context, Icons.email, 'support@namasteindia.app'),
          ],
        ),
      );

  Widget _contactRow(BuildContext context, IconData icon, String value) =>
      InkWell(
        onTap: () => _copy(context, value, value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const Icon(Icons.copy, color: Colors.white70, size: 18),
            ],
          ),
        ),
      );

  Widget _ticketForm() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Subject',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. Driver ne ride cancel kar di'),
            ),
            const SizedBox(height: 12),
            const Text('Message',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Apni dikkat detail me likhiye...'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitTicket,
                child: const Text('Ticket Bhejo',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _confirmationCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.success.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                color: AppTheme.success, size: 48),
            const SizedBox(height: 10),
            const Text('Ticket mil gaya!',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Ticket ID: $_ticketId',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            const SizedBox(height: 6),
            Text(
              'Hamari team 24 ghante me jawab degi.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _submitted = false),
              child: const Text('Ek aur ticket banao'),
            ),
          ],
        ),
      );
}
