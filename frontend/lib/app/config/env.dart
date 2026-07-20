import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central accessor for environment configuration.
///
/// Values are loaded from the `.env` file (see `.env.example`) via
/// `flutter_dotenv` at app startup in `main.dart`. Never hardcode secrets
/// here — this file only reads what `.env` provides. Secret keys (Stripe
/// secret key, AI provider keys, Firebase service account) must NEVER be
/// referenced from the Flutter app; those live exclusively in the FastAPI
/// backend's environment.
class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8000');

  static String get stripePublishableKey =>
      dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');

  static String get firebaseApiKey =>
      dotenv.get('FIREBASE_API_KEY', fallback: '');

  static String get firebaseAppId =>
      dotenv.get('FIREBASE_APP_ID', fallback: '');

  static String get firebaseMessagingSenderId =>
      dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');

  static String get firebaseProjectId =>
      dotenv.get('FIREBASE_PROJECT_ID', fallback: '');

  static bool get isProduction =>
      dotenv.get('ENV', fallback: 'development') == 'production';
}
