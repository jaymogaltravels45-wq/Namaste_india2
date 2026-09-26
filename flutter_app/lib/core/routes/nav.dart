import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// App-wide navigation contract.
///
/// - [go]   : top-level switches only (bottom nav, auth flow, logout,
///            flow completion like rating -> home). Replaces the stack.
/// - [push] : every drill-down / forward step (list -> detail, home -> profile,
///            profile -> settings, ...). Keeps history so the system Back
///            button, edge-swipe and in-app Back all return to the previous
///            screen. Silently ignores pushing the location that is already
///            on top (duplicate guard).
/// - [pop]  : in-app Back buttons. Never jumps to Home, never exits the app
///            while a previous route exists.
class Nav {
  static void go(BuildContext context, String location, {Object? extra}) {
    context.go(location, extra: extra);
  }

  /// Push [location] unless it is already the current one.
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String location, {
    Object? extra,
  }) {
    final current = GoRouterState.of(context).uri.toString();
    if (current == location) return Future<T?>.value(null);
    return context.push<T>(location, extra: extra);
  }

  static void pop(BuildContext context, [Object? result]) =>
      context.pop(result);

  static bool canPop(BuildContext context) => context.canPop();
}
