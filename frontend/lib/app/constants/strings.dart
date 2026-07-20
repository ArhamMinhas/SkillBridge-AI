/// App-wide copy constants. Centralized so wording changes and future
/// localization don't require hunting through screen files.
class AppStrings {
  AppStrings._();

  static const String appName = 'SkillBridge AI';

  // Auth
  static const String welcomeBack = 'Welcome back';
  static const String joinSkillBridge = 'Join SkillBridge AI';
  static const String loginSubtitle = 'Sign in to continue your career journey';
  static const String alreadyHaveAccount = 'Already have an account? Login';
  static const String dontHaveAccount = "Don't have an account? Register";
  static const String forgotPassword = 'Forgot Password?';
  static const String sendRecoveryLink = 'Send Recovery Link';

  // Errors
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidPassword =
      'Password must be at least 8 characters';
  static const String loginFailed =
      'Login failed. Please check your credentials';
  static const String registrationFailed =
      'Registration failed. Please try again';
  static const String networkUnavailable =
      'Network unavailable. Check your connection';
  static const String serverUnavailable =
      'Server unavailable. Please try again later';
  static const String aiRequestFailed = 'AI request failed. Please try again';
  static const String permissionDenied = 'Permission denied';

  // Success
  static const String loginSuccessful = 'Login successful';
  static const String registrationSuccessful = 'Registration successful';
  static const String resumeUploadedSuccessfully =
      'Resume uploaded successfully';
  static const String profileUpdatedSuccessfully =
      'Profile updated successfully';
  static const String paymentSuccessful = 'Payment successful';
  static const String subscriptionActivated = 'Subscription activated';

  // Empty states
  static const String noJobsFound = 'No jobs found';
  static const String noNotifications = 'No notifications yet';
  static const String noInterviewHistory = 'No interview history yet';
  static const String noResumeUploaded = 'No resume uploaded yet';
  static const String noSavedJobs = 'No saved jobs yet';
  static const String noAnalyticsAvailable = 'No analytics available yet';
  static const String noInternetConnection = 'No internet connection';
}
