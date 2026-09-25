import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

// KEY RULE: Negative balance -> block bookings
// TIME BUG FIX: Always display pickup_time from server
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override State<DriverHomeScreen> createState() => _State();
}

class _State extends State<DriverHomeScreen> {
  double _balance = 150.0; // TODO: fetch from API
  bool _online = false;
  List<Map<String,dynamic>> _requests = [];

  bool get _canBook => _balance >= 0;

  @override void initState() { super.initState(); _loadData(); }

  void _loadData() {
    // TODO: Replace with real API: GET /api/drivers/wallet
    setState(() {
      if (_canBook) {
        _requests = [{
          "id": "BK001",
          "from": "Ahmedabad",
          "to": "Vadodara",
          "dist": "110 KM",
          "amt": "Rs.1,620",
          "vehicle": "Sedan",
          "pickup_time": "10:30 AM", // TIME BUG FIX: from server DB
          "type": "outstation",
        }];
      }
    });
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(
      title: const Text("Namaste India - Driver"),
      actions: [Padding(
        padding: const EdgeInsets.only(right: 12),
        child: GestureDetector(
          onTap: () => ctx.go("/driver/wallet"),
          child: Chip(
            avatar: Icon(Icons.account_balance_wallet, size: 16,
              color: _canBook ? Colors.green : Colors.red),
            label: Text("Rs." + _balance.toStringAsFixed(0),
              style: TextStyle(fontWeight: FontWeight.bold,
                color: _canBook ? Colors.green : Colors.red)),
            backgroundColor: Colors.white)))],
    ),
    body: Column(children: [
      if (!_canBook) _negativeBanner(),
      _toggleRow(),
      Expanded(child: _canBook && _requests.isNotEmpty ? _list() : _emptyView()),
    ]));

  Widget _negativeBanner() => Container(
    color: Colors.red.shade700, width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(
        "Wallet Rs." + _balance.toStringAsFixed(0) + " - negative balance, bookings blocked!",
        style: const TextStyle(color: Colors.white, fontSize: 12))),
      TextButton(onPressed: () => context.go("/driver/add-money"),
        child: const Text("Add Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    ]));

  Widget _toggleRow() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      Text(_online ? "Online - Requests ON" : "Offline",
        style: TextStyle(fontWeight: FontWeight.w600, color: _online ? Colors.green : Colors.grey)),
      const Spacer(),
      Switch(value: _online && _canBook,
        onChanged: _canBook ? (v) => setState(() => _online = v) : null,
        activeColor: Colors.green),
    ]));

  Widget _list() => ListView.builder(
    padding: const EdgeInsets.all(12), itemCount: _requests.length,
    itemBuilder: (_, i) => _RequestCard(
      data: _requests[i],
      onAccept: () => context.go("/driver/my-booking/" + _requests[i]["id"]),
      onDecline: () => setState(() => _requests.removeAt(i))));

  Widget _emptyView() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(_canBook ? Icons.hourglass_empty : Icons.block,
        size: 72, color: _canBook ? Colors.grey.shade300 : Colors.red),
      const SizedBox(height: 12),
      Text(_canBook ? "No requests yet" : "Blocked - negative balance",
        style: const TextStyle(color: Colors.grey)),
      if (!_canBook) ...[
        const SizedBox(height: 16),
        ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text("Add Money"),
          onPressed: () => context.go("/driver/add-money")),
      ],
    ]));
}

class _RequestCard extends StatelessWidget {
  final Map<String,dynamic> data;
  final VoidCallback onAccept, onDecline;
  const _RequestCard({required this.data, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext ctx) {
    // TIME BUG FIX: Always display pickup_time from server
    final time = (data["pickup_time"]?.toString().isNotEmpty == true)
      ? data["pickup_time"] : "N/A";
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3,
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on, color: Colors.red, size: 16), const SizedBox(width: 4),
          Expanded(child: Text(
            (data["from"] ?? "") + " -> " + (data["to"] ?? ""),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
            child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.directions_car, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(data["vehicle"] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          const Icon(Icons.route, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(data["dist"] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text(data["amt"] ?? "",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: onDecline,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text("Decline"))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: onAccept,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Accept"))),
        ]),
      ])));
  }
}
