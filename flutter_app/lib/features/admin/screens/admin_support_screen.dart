import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Support tickets — seeded list, detail view with replies,
/// mark resolved. (Local state; backend ticket API nahi hai.)
class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-101',
      'user': 'Ramesh Kumar',
      'phone': '+919876543210',
      'subject': 'Driver ne extra paise mange',
      'status': 'open',
      'time': 'Aaj, 10:24 AM',
      'messages': [
        {'from': 'user', 'text': 'Driver ne fixed fare se ₹200 zyada mange.'},
        {
          'from': 'admin',
          'text': 'Maafi chahte hain. Hum driver se baat karke update denge.'
        },
      ],
    },
    {
      'id': 'TKT-102',
      'user': 'Priya Sharma',
      'phone': '+919123456789',
      'subject': 'Refund nahi mila cancelled trip ka',
      'status': 'in-progress',
      'time': 'Kal, 6:41 PM',
      'messages': [
        {
          'from': 'user',
          'text': 'Trip cancel hui thi, wallet me refund abhi tak nahi aaya.'
        },
      ],
    },
    {
      'id': 'TKT-103',
      'user': 'Amit Patel',
      'phone': '+918888877777',
      'subject': 'OTP nahi aa raha tha',
      'status': 'resolved',
      'time': '2 din pehle',
      'messages': [
        {'from': 'user', 'text': 'Login ke time OTP late aa raha tha.'},
        {
          'from': 'admin',
          'text': 'MSG91 route theek kar diya hai. Ab try karein.'
        },
        {'from': 'user', 'text': 'Ab kaam kar raha hai. Dhanyavaad!'},
      ],
    },
  ];

  String _filter = 'all';

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _tickets
      : _tickets.where((t) => t['status'] == _filter).toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'open':
        return AppTheme.error;
      case 'in-progress':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'open':
        return 'Open';
      case 'in-progress':
        return 'In Progress';
      default:
        return 'Resolved';
    }
  }

  void _openTicket(Map<String, dynamic> ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TicketDetailPage(
          ticket: ticket,
          onChanged: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _tickets.where((t) => t['status'] == 'open').length;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Support Tickets')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_outlined,
                    color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$openCount open ticket${openCount == 1 ? '' : 's'} — pehle inhe niptao.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['all', 'open', 'in-progress', 'resolved'].map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(f)),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppTheme.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color:
                          active ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Koi ticket nahi.',
                        style:
                            TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (c, i) {
                      final t = _filtered[i];
                      final status = t['status'].toString();
                      return GestureDetector(
                        onTap: () => _openTicket(t),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(t['id'].toString(),
                                        style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(t['subject'].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${t['user']} • ${t['time']}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_statusLabel(status),
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailPage extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onChanged;
  const _TicketDetailPage(
      {required this.ticket, required this.onChanged});

  @override
  State<_TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<_TicketDetailPage> {
  final _replyCtrl = TextEditingController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _messages =>
      (widget.ticket['messages'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _sendReply() {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      (widget.ticket['messages'] as List)
          .add({'from': 'admin', 'text': text});
      if (widget.ticket['status'] == 'open') {
        widget.ticket['status'] = 'in-progress';
      }
    });
    widget.onChanged();
    _replyCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Reply bhej diya.'),
          backgroundColor: AppTheme.success),
    );
  }

  void _resolve() {
    setState(() => widget.ticket['status'] = 'resolved');
    widget.onChanged();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Ticket resolved mark ho gaya.'),
          backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final resolved = t['status'] == 'resolved';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(t['id'].toString())),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['subject'].toString(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${t['user']} • ${t['phone']}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (c, i) {
                final m = _messages[i];
                final mine = m['from'] == 'admin';
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: mine
                          ? AppTheme.primary
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: mine
                          ? null
                          : Border.all(color: AppTheme.border),
                    ),
                    child: Text(m['text'].toString(),
                        style: TextStyle(
                            color: mine
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontSize: 13.5)),
                  ),
                );
              },
            ),
          ),
          if (!resolved)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: AppTheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      decoration: const InputDecoration(
                          hintText: 'Reply likho…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: AppTheme.primary),
                    onPressed: _sendReply,
                  ),
                ],
              ),
            ),
          if (!resolved)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Resolved'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: const BorderSide(color: AppTheme.success)),
                  onPressed: _resolve,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      color: AppTheme.success, size: 18),
                  SizedBox(width: 6),
                  Text('Ye ticket resolved hai',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
