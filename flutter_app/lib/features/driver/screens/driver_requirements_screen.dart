import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../core/theme/app_theme.dart";

/// Simple in-memory store shared with PostRequirementScreen.
class DriverRequirement {
  final String title;
  final String route;
  final String vehicle;
  final String date;
  String status;
  DriverRequirement({
    required this.title,
    required this.route,
    required this.vehicle,
    required this.date,
    this.status = "Open",
  });
}

class RequirementStore {
  static final List<DriverRequirement> items = [
    DriverRequirement(
      title: "Daily office pickup",
      route: "Ahmedabad → Gandhinagar",
      vehicle: "Sedan",
      date: "Mon–Fri",
    ),
    DriverRequirement(
      title: "Airport drop",
      route: "Vadodara → Airport",
      vehicle: "SUV",
      date: "28 Sep",
    ),
  ];

  static void add(DriverRequirement r) => items.insert(0, r);
  static void remove(DriverRequirement r) => items.remove(r);
}

class DriverRequirementsScreen extends StatefulWidget {
  const DriverRequirementsScreen({super.key});
  @override
  State<DriverRequirementsScreen> createState() =>
      _DriverRequirementsScreenState();
}

class _DriverRequirementsScreenState extends State<DriverRequirementsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("My Requirements",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: RequirementStore.items.isEmpty
            ? _emptyView()
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: RequirementStore.items.length,
                itemBuilder: (_, i) =>
                    _reqCard(RequirementStore.items[i]),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context
              .push("/driver/requirements/post")
              .then((_) => setState(() {})),
          icon: const Icon(Icons.add),
          label: const Text("Post Requirement"),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
        ),
      );

  Widget _emptyView() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.post_add_outlined,
                size: 72, color: AppTheme.border),
            SizedBox(height: 12),
            Text("Koi requirement nahi hai",
                style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text("Neeche button se nayi requirement post karo",
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ),
      );

  Widget _reqCard(DriverRequirement r) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(r.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15))),
                  _statusChip(r.status),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.route,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(r.route,
                          style: const TextStyle(fontSize: 13))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.directions_car,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(r.vehicle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(r.date,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => r.status =
                            r.status == "Open" ? "Closed" : "Open");
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Text(
                              "Requirement ${r.status == "Open" ? "phir se open" : "close"} kar di"),
                        ));
                      },
                      icon: Icon(
                          r.status == "Open"
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 16),
                      label: Text(r.status == "Open"
                          ? "Close"
                          : "Reopen"),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.error),
                    tooltip: "Delete",
                    onPressed: () {
                      setState(
                          () => RequirementStore.remove(r));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text(
                                  "Requirement delete ho gayi")));
                    },
                  ),
                ]),
              ]),
        ),
      );

  Widget _statusChip(String status) {
    final open = status == "Open";
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: (open ? AppTheme.success : AppTheme.textSecondary)
              .withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: open
                  ? AppTheme.success
                  : AppTheme.textSecondary)),
    );
  }
}
