import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "core/config/app_config.dart";
import "core/l10n/app_strings.dart";
import "core/routes/app_router.dart";
import "core/theme/app_theme.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SECURITY: never crash on missing config — show setup instructions instead.
  if (!AppConfig.isConfigured) {
    runApp(const MissingConfigApp());
    return;
  }
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  await AppLang.load();
  runApp(const NamasteIndiaApp());
}

class NamasteIndiaApp extends StatelessWidget {
  const NamasteIndiaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: AppConfig.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routerConfig: AppRouter.router,
  );
}

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not injected at build time.
class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text("Configuration missing",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "SUPABASE_URL and SUPABASE_ANON_KEY were not provided.\n\n"
                "Rebuild with:\n"
                "flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
