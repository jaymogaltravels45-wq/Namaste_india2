import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "package:namaste_india/core/routes/app_router.dart";
import "package:namaste_india/core/widgets/premium.dart";
import "package:namaste_india/features/booking/widgets/map_location_picker.dart";
import "package:namaste_india/features/customer/screens/available_cars_screen.dart";
import "package:namaste_india/features/customer/screens/customer_notifications_screen.dart";
import "package:namaste_india/features/driver/screens/driver_notifications_screen.dart";

/// Acceptance suite: back button, routes, map, login-adjacent screens.
void main() {
  setUpAll(() async {
    // Dummy Supabase taaki auth header code crash na kare (koi network nahi).
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: "https://example.supabase.co",
      anonKey: "dummy-anon-key",
    );
  });

  List<String> _allPaths() {
    final out = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) {
          out.add(r.path);
          walk(r.routes);
        }
      }
    }
    walk(AppRouter.router.configuration.routes);
    return out;
  }

  test("saare zaroori routes maujood hain", () {
    final paths = _allPaths();
    for (final p in [
      "/",
      "/role",
      "/login",
      "/otp",
      "/customer",
      "/customer/booking",
      "/customer/cars",
      "/customer/notifications",
      "/customer/wallet",
      "/driver",
      "/driver/kyc",
      "/driver/notifications",
      "/driver/wallet",
      "/driver/earnings",
      "/driver/subscription",
      "/admin/dashboard",
    ]) {
      expect(paths, contains(p), reason: "route missing: $p");
    }
  });

  testWidgets("back button: pehli baar hint, doosri baar exit",
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DoubleTapToExit(
          child: Scaffold(body: Text("home-screen")),
        ),
      ),
    );
    expect(find.text("home-screen"), findsOneWidget);

    // Pehla back — snackbar, screen wahin
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text("Wapas back dabao app band karne ke liye"),
        findsOneWidget);
    expect(find.text("home-screen"), findsOneWidget);

    // Doosra back 2 second ke andar — exit (pop)
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text("home-screen"), findsNothing);
  });

  testWidgets("OSM map picker crash kiye bina khulta hai", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MapLocationPicker(title: "Pickup"),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    // Map widget tree me hai, crash nahi hua
    expect(find.byType(MapLocationPicker), findsOneWidget);
    expect(find.text("Pickup"), findsOneWidget);
  });

  testWidgets("Available Cars screen khulti hai", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AvailableCarsScreen()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(AvailableCarsScreen), findsOneWidget);
    expect(find.text("Available Cars"), findsOneWidget);
  });

  testWidgets("Customer Notifications screen khulti hai", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CustomerNotificationsScreen()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(CustomerNotificationsScreen), findsOneWidget);
    expect(find.text("Notifications"), findsOneWidget);
  });

  testWidgets("Driver Notifications screen khulti hai", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DriverNotificationsScreen()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(DriverNotificationsScreen), findsOneWidget);
    expect(find.text("Notifications"), findsOneWidget);
  });
}
