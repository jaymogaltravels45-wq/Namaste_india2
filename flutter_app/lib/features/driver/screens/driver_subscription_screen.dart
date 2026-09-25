import "package:flutter/material.dart";
import "../../../core/theme/app_theme.dart";

class DriverSubscriptionScreen extends StatefulWidget {
  const DriverSubscriptionScreen({super.key});
  @override
  State<DriverSubscriptionScreen> createState() =>
      _DriverSubscriptionScreenState();
}

class _Plan {
  final String id;
  final String name;
  final int price;
  final String period;
  final List<String> perks;
  const _Plan(
      {required this.id,
      required this.name,
      required this.price,
      required this.period,
      required this.perks});
}

class _DriverSubscriptionScreenState extends State<DriverSubscriptionScreen> {
  String _currentPlan = "monthly";
  bool _busy = false;

  static const _plans = [
    _Plan(
      id: "weekly",
      name: "Weekly",
      price: 199,
      period: "7 din",
      perks: ["Priority requests", "Zero commission 7 din", "Support priority"],
    ),
    _Plan(
      id: "monthly",
      name: "Monthly",
      price: 699,
      period: "30 din",
      perks: [
        "Priority requests",
        "Zero commission 30 din",
        "Free cancellation cover",
        "Support priority"
      ],
    ),
    _Plan(
      id: "quarterly",
      name: "Quarterly",
      price: 1799,
      period: "90 din",
      perks: [
        "Sab monthly wale fayde",
        "Festival bonus eligibility",
        "Dedicated manager"
      ],
    ),
  ];

  void _subscribe(_Plan plan) {
    if (plan.id == _currentPlan) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${plan.name} Plan lo?"),
        content: Text(
            "Rs.${plan.price} (${plan.period}) ka ${plan.name} plan activate ho jayega. Wallet se paise katenge."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirm(plan);
              },
              child: const Text("Confirm")),
        ],
      ),
    );
  }

  void _confirm(_Plan plan) {
    setState(() => _busy = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _currentPlan = plan.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${plan.name} plan activate ho gaya!"),
        backgroundColor: AppTheme.success,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final current =
        _plans.firstWhere((p) => p.id == _currentPlan, orElse: () => _plans[1]);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Subscription",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _currentCard(current),
              const SizedBox(height: 20),
              const Text("Plans",
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._plans.map((p) => _planCard(p)),
              const SizedBox(height: 12),
              const Text(
                "Note: Subscription wallet balance se kat-ta hai. Cancel kabhi bhi kar sakte ho.",
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]),
      ),
    );
  }

  Widget _currentCard(_Plan current) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Color(0xFF6A1B9A),
            Color(0xFF9C27B0),
          ]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.card_membership,
              color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text("Current Plan",
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text("${current.name} · Rs.${current.price}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text("Valid: ${current.period}",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: const Text("ACTIVE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      );

  Widget _planCard(_Plan plan) {
    final isCurrent = plan.id == _currentPlan;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isCurrent ? AppTheme.success : AppTheme.border,
            width: isCurrent ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(plan.name,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold))),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color:
                            AppTheme.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text("Current",
                        style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text("Rs.${plan.price} · ${plan.period}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
              const SizedBox(height: 8),
              ...plan.perks.map((perk) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: AppTheme.success),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(perk,
                              style: const TextStyle(
                                  fontSize: 13))),
                    ]),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isCurrent || _busy)
                      ? null
                      : () => _subscribe(plan),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent
                          ? Colors.grey.shade300
                          : AppTheme.primary,
                      foregroundColor: isCurrent
                          ? Colors.grey.shade600
                          : Colors.white),
                  child: Text(isCurrent
                      ? "Active Hai"
                      : "Rs.${plan.price} me Lo"),
                ),
              ),
            ]),
      ),
    );
  }
}
