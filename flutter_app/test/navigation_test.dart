import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:namaste_india/core/routes/nav.dart';
import 'package:namaste_india/core/widgets/premium.dart';

/// Covers the back-navigation contract:
/// A. Home -> Profile -> Settings -> Back -> Profile
/// B. Profile -> Settings -> edge-swipe(system back) -> Profile
/// C. Booking List -> Detail -> Back -> List
/// D. Dialog open -> Back -> dialog closes first
/// E. Bottom sheet open -> Back -> sheet closes first
/// F. Home at root -> Back -> hint, 2nd Back -> minimize (never random nav)
/// I. Rapid pushes/pops -> no crash; duplicate push guarded
Widget _page(String name, {List<Widget> extra = const []}) => Scaffold(
      body: Column(children: [
        Text('page-$name', textDirection: TextDirection.ltr),
        ...extra,
      ]),
    );

GoRouter _router({bool wrapHomeInExitGuard = false, String initial = '/home'}) {
  Widget home(BuildContext c) {
    final p = _page('home', extra: [
      Builder(
        builder: (bc) => TextButton(
          onPressed: () => Nav.push(bc, '/profile'),
          child: const Text('go-profile'),
        ),
      ),
      Builder(
        builder: (bc) => TextButton(
          onPressed: () => showDialog(
            context: bc,
            builder: (_) => const AlertDialog(content: Text('dlg')),
          ),
          child: const Text('open-dialog'),
        ),
      ),
      Builder(
        builder: (bc) => TextButton(
          onPressed: () => showModalBottomSheet(
            context: bc,
            builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
          ),
          child: const Text('open-sheet'),
        ),
      ),
    ]);
    return wrapHomeInExitGuard ? DoubleTapToExit(child: p) : p;
  }

  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/home', builder: (c, s) => home(c)),
      GoRoute(
        path: '/profile',
        builder: (c, s) => _page('profile', extra: [
          Builder(
            builder: (bc) => TextButton(
              onPressed: () => Nav.push(bc, '/settings'),
              child: const Text('go-settings'),
            ),
          ),
        ]),
      ),
      GoRoute(path: '/settings', builder: (c, s) => _page('settings')),
      GoRoute(
        path: '/bookings',
        builder: (c, s) => _page('bookings', extra: [
          Builder(
            builder: (bc) => TextButton(
              onPressed: () => Nav.push(bc, '/bookings/1'),
              child: const Text('open-detail'),
            ),
          ),
        ]),
      ),
      GoRoute(
          path: '/bookings/:id',
          builder: (c, s) => _page('detail-${s.pathParameters['id']}')),
      for (var i = 1; i <= 10; i++)
        GoRoute(path: '/p$i', builder: (c, s) => _page('p$i')),
    ],
  );
}

/// Records whether a system-Back reached the end of the observer chain
/// (i.e. the app would exit/minimize on a device).
class _ProbeObserver extends WidgetsBindingObserver {
  final List<String> calls;
  _ProbeObserver(this.calls);
  @override
  Future<bool> didPopRoute() async {
    calls.add('pop');
    return false;
  }
}

Future<void> _pump(WidgetTester t, GoRouter r) async {
  await t.pumpWidget(MaterialApp.router(routerConfig: r));
  await t.pumpAndSettle();
}

/// System Back (button AND edge-swipe arrive through this same dispatch).
Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

void main() {
  testWidgets('A: Home->Profile->Settings->Back lands on Profile',
      (t) async {
    final r = _router();
    await _pump(t, r);
    await t.tap(find.text('go-profile'));
    await t.pumpAndSettle();
    await t.tap(find.text('go-settings'));
    await t.pumpAndSettle();
    expect(find.text('page-settings'), findsOneWidget);
    await _back(t); // system back
    expect(find.text('page-profile'), findsOneWidget);
    expect(find.text('page-settings'), findsNothing);
  });

  testWidgets('B: edge-swipe back from Settings returns to Profile',
      (t) async {
    final r = _router();
    await _pump(t, r);
    r.push('/profile');
    await t.pumpAndSettle();
    r.push('/settings');
    await t.pumpAndSettle();
    await _back(t); // same dispatch as the edge-swipe gesture
    expect(find.text('page-profile'), findsOneWidget);
  });

  testWidgets('C: Booking List->Detail->Back returns to List, not Home/exit',
      (t) async {
    final r = _router(initial: '/bookings');
    await _pump(t, r);
    await t.tap(find.text('open-detail'));
    await t.pumpAndSettle();
    expect(find.text('page-detail-1'), findsOneWidget);
    await _back(t);
    expect(find.text('page-bookings'), findsOneWidget);
  });

  testWidgets('D: Back with dialog open closes dialog first', (t) async {
    final r = _router();
    await _pump(t, r);
    await t.tap(find.text('open-dialog'));
    await t.pumpAndSettle();
    expect(find.text('dlg'), findsOneWidget);
    await _back(t);
    expect(find.text('dlg'), findsNothing);
    expect(find.text('page-home'), findsOneWidget); // page untouched
  });

  testWidgets('E: Back with bottom sheet open closes sheet first',
      (t) async {
    final r = _router();
    await _pump(t, r);
    await t.tap(find.text('open-sheet'));
    await t.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    await _back(t);
    expect(find.text('sheet'), findsNothing);
    expect(find.text('page-home'), findsOneWidget);
  });

  testWidgets(
      'F: at root, 1st Back shows hint (consumed), 2nd Back exits (propagates)',
      (t) async {
    final r = _router(wrapHomeInExitGuard: true);
    await _pump(t, r);
    // Probe added last: it only fires when every earlier observer declines.
    final probeCalls = <String>[];
    final probe = _ProbeObserver(probeCalls);
    WidgetsBinding.instance.addObserver(probe);

    await t.binding.handlePopRoute(); // 1st back
    await t.pump(); // single frame: snackbar visible, not yet auto-dismissed
    expect(find.text('page-home'), findsOneWidget); // still here
    expect(find.byType(SnackBar), findsOneWidget); // hint shown
    expect(probeCalls, isEmpty); // consumed -> system would NOT exit

    await t.binding.handlePopRoute(); // 2nd back within 2s
    await t.pump();
    expect(probeCalls, ['pop']); // propagated -> system minimizes/exits
    WidgetsBinding.instance.removeObserver(probe);
  });

  testWidgets('Back navigates to previous route even under DoubleTapToExit',
      (t) async {
    final r = _router(wrapHomeInExitGuard: true);
    await _pump(t, r);
    r.push('/profile'); // history now exists under home
    await t.pumpAndSettle();
    await _back(t);
    // Must go back to home WITHOUT the exit hint (old bug swallowed it).
    expect(find.text('page-home'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('I: rapid pushes/pops do not crash; duplicates guarded',
      (t) async {
    final r = _router();
    await _pump(t, r);
    final ctx = t.element(find.byType(Scaffold).first);
    Nav.push(ctx, '/home'); // duplicate of current -> ignored
    await t.pumpAndSettle();
    expect(r.routerDelegate.currentConfiguration.uri.toString(), '/home');
    for (var i = 1; i <= 10; i++) {
      Nav.push(ctx, '/p$i');
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(find.text('page-p10'), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      await _back(t);
    }
    expect(find.text('page-home'), findsOneWidget); // full unwind, no crash
  });

  testWidgets('in-app back (Nav.pop) returns to previous, never Home/exit',
      (t) async {
    final r = _router();
    await _pump(t, r);
    r.push('/profile');
    await t.pumpAndSettle();
    r.push('/settings');
    await t.pumpAndSettle();
    Nav.pop(t.element(find.text('page-settings')));
    await t.pumpAndSettle();
    expect(find.text('page-profile'), findsOneWidget);
  });
}
