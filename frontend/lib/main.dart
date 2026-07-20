import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: let the app's own background paint under the status bar
  // and navigation bar instead of the OS letterboxing them in opaque black.
  // Per-screen icon/bar brightness is then kept in sync with the active
  // theme via the AnnotatedRegion in SkillBridgeApp's builder below.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load `.env` (see .env.example) before anything reads Env.*
  await dotenv.load(fileName: '.env');

  // Fail soft: a platform DefaultFirebaseOptions hasn't been configured yet
  // (e.g. iOS/desktop) or the device has no connectivity on first launch —
  // let the UI still run, with FirebaseStatus.isAvailable gating anything
  // that needs a live Firebase connection.
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseStatus.isAvailable = true;

    // Crashlytics doesn't support web — leave Flutter's default error
    // handler in place there.
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }

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
      // Keeps the status/nav bar icons legible against whichever theme is
      // active, and cross-fades ThemeData changes instead of the instant,
      // jarring snap Flutter applies by default when themeMode changes.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: AnimatedTheme(
            data: isDark ? AppTheme.dark : AppTheme.light,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: child!,
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
