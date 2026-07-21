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

class SkillBridgeApp extends ConsumerStatefulWidget {
  const SkillBridgeApp({super.key});

  @override
  ConsumerState<SkillBridgeApp> createState() => _SkillBridgeAppState();
}

class _SkillBridgeAppState extends ConsumerState<SkillBridgeApp>
    with SingleTickerProviderStateMixin {
  // Flashes a brief scrim over the instant theme swap instead of animating
  // the real ThemeData across the whole tree. AnimatedTheme was tried first
  // and interpolates every Color/TextStyle in ThemeData on every frame for
  // every descendant that reads Theme.of(context) — across this app's full
  // widget tree (five kept-alive bottom-nav branches via IndexedStack, each
  // with glass cards / gradients / shadows) that's expensive enough to drop
  // frames, which is exactly the "laggy toggle" the animation was supposed
  // to fix. A one-shot opacity flash on a single full-screen Container costs
  // a tiny fraction of that while still reading as a smooth transition.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen(themeModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        _flash.forward(from: 0);
      }
    });

    return MaterialApp.router(
      title: 'SkillBridge AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Keeps the status/nav bar icons legible against whichever theme is
      // active; the flash overlay below masks the instant ThemeData swap
      // Flutter applies underneath.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scrimColor =
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
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
          child: RepaintBoundary(
            child: Stack(
              children: [
                RepaintBoundary(child: child!),
                IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _flash,
                      builder: (context, _) {
                        final t = _flash.value;
                        if (t <= 0 || t >= 1) return const SizedBox.shrink();
                        // Fast rise, slower fall — reads as a quick flash
                        // rather than a lingering fade.
                        final opacity = t < 0.35
                            ? (t / 0.35)
                            : (1 - (t - 0.35) / 0.65).clamp(0.0, 1.0);
                        return Positioned.fill(
                          child: Container(
                            color: scrimColor.withOpacity(opacity * 0.85),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
