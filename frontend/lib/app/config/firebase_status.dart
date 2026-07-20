/// Tracks whether Firebase actually initialized successfully.
///
/// Until a real Firebase project is wired up (google-services.json on
/// Android + FlutterFire config), `Firebase.initializeApp()` in main.dart
/// fails fast and is caught rather than crashing the app. Screens that talk
/// to FirebaseAuth/Firestore/FCM should check [FirebaseStatus.isAvailable]
/// first so the UI stays usable during early development instead of
/// throwing on every Firebase call.
class FirebaseStatus {
  FirebaseStatus._();

  static bool isAvailable = false;
}
