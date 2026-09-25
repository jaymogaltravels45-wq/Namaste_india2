import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey.shade100,
    body: CustomScrollView(slivers: [
      _hero(context),
      SliverToBoxAdapter(child: _body(context)),
    ]),
    bottomNavigationBar: _bottomNav(context),
  );

  SliverAppBar _hero(BuildContext ctx) => SliverAppBar(
    expandedHeight: 200, pinned: true, backgroundColor: const Color(0xFF0D47A1),
    flexibleSpace: FlexibleSpaceBar(background: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.directions_car, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            const Text("Namaste India", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
          ]),
          const SizedBox(height: 12),
          const Text("Kahan jaana hai aaj?", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const TextField(decoration: InputDecoration(
              hintText: "Pickup location...",
              prefixIcon: Icon(Icons.search, color: Color(0xFF0D47A1)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          ),
        ]))))));

  Widget _body(BuildContext ctx) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Book a Ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
        children: [
          _rideCard(ctx, "One Way",    Icons.arrow_forward, const Color(0xFF1565C0), "outstation"),
          _rideCard(ctx, "Round Trip", Icons.sync_alt,      const Color(0xFF2E7D32), "round"),
          _rideCard(ctx, "Local",      Icons.location_city, const Color(0xFFE65100), "local"),
          _rideCard(ctx, "Bid",        Icons.gavel,         const Color(0xFF6A1B9A), "bid"),
        ]),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)]),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Popular Routes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("Ahmedabad - Surat - Vadodara", style: TextStyle(color: Colors.white70, fontSize: 12))])),
          ElevatedButton(onPressed: () => ctx.go("/customer/booking"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0D47A1)),
            child: const Text("Book")),
        ])),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _trust(Icons.verified_user, "Safe"),
        _trust(Icons.access_time, "24/7"),
        _trust(Icons.currency_rupee, "Fair Fare"),
        _trust(Icons.star, "Rated 4.8"),
      ]),
      const SizedBox(height: 20),
    ]));

  Widget _rideCard(BuildContext ctx, String lbl, IconData icon, Color c, String type) =>
    GestureDetector(
      onTap: () => ctx.go("/customer/booking", extra: {"type": type}),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0,2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: c, size: 28)),
          const SizedBox(height: 8),
          Text(lbl, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ])));

  Widget _trust(IconData i, String l) => Column(children: [
    Icon(i, color: const Color(0xFF1565C0), size: 22),
    const SizedBox(height: 4),
    Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))]);

  Widget _bottomNav(BuildContext ctx) => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF1565C0),
    currentIndex: 0,
    onTap: (i) {
      const routes = ["/customer","/customer/booking","/customer/history","/customer/profile"];
      if (i < routes.length) ctx.go(routes[i]);
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Book"),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: "Trips"),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
    ]);
}
