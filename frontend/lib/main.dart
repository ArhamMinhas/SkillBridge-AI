import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app/config/env.dart';
import 'app/config/firebase_status.dart';
import 'app/config/routes.dart';
import 'app/config/theme.dart';
import 'app/providers/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load `.env` (see .env.example) before anything reads Env.*
  await dotenv.load(fileName: '.env');

  // Firebase isn't configured yet for this project (no google-services.json
  // / FlutterFire options) — fail soft so the UI still runs during early
  // screen development. Once a real Firebase project is wired up, this
  // succeeds and FirebaseStatus.isAvailable flips to true.
  try {
    await Firebase.initializeApp();
    FirebaseStatus.isAvailable = true;

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    if (Env.stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = Env.stripePublishableKey;
    }
  } catch (error) {
    FirebaseStatus.isAvailable = false;
    debugPrint('Firebase not configured yet — running without it: $error');
  }

  runApp(const ProviderScope(child: SkillBridgeApp()));
}

class SkillBridgeApp extends ConsumerWidget {
  const SkillBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'SkillBridge AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
