import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/shared_widgets/main_shell.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/profile_setup_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/progress_analytics_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/resume/presentation/screens/resume_upload_screen.dart';
import '../../features/resume/presentation/screens/resume_analysis_result_screen.dart';
import '../../features/skills/presentation/screens/skill_assessment_screen.dart';
import '../../features/skills/presentation/screens/skill_gap_report_screen.dart';
import '../../features/roadmap/presentation/screens/career_roadmap_screen.dart';
import '../../features/roadmap/presentation/screens/learning_resources_screen.dart';
import '../../features/jobs/presentation/screens/job_matching_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/ai_features/presentation/screens/ai_mock_interview_screen.dart';
import '../../features/ai_features/presentation/screens/ai_chatbot_screen.dart';
import '../../features/subscription/presentation/screens/premium_subscription_screen.dart';
import '../../features/subscription/presentation/screens/payment_status_screen.dart';

/// Central route path registry — screens navigate via these constants
/// instead of hardcoding path strings (`context.go(AppRoutes.jobDetail)`).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const register = '/register';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const profileSetup = '/profile-setup';
  static const dashboard = '/dashboard';
  static const progressAnalytics = '/progress-analytics';
  static const adminDashboard = '/admin-dashboard';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const resumeUpload = '/resume-upload';
  static const resumeResult = '/resume-result';
  static const skillAssessment = '/skill-assessment';
  static const skillGapReport = '/skill-gap-report';
  static const careerRoadmap = '/career-roadmap';
  static const learningResources = '/learning-resources';
  static const jobMatching = '/job-matching';
  static const jobDetail = '/job-detail';
  static const aiMockInterview = '/ai-mock-interview';
  static const aiChatbot = '/ai-chatbot';
  static const premiumSubscription = '/premium-subscription';
  static const paymentSuccess = '/payment-success';
  static const paymentFailure = '/payment-failure';
}

/// Fade-through page transition used between bottom-nav-level screens.
/// Adjacent flow screens (e.g. login -> register) use the default
/// MaterialPage transition (shared-axis-like slide), left as GoRoute default.
CustomTransitionPage<void> _fadeThroughPage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen()),
    GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen()),
    GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.progressAnalytics,
      pageBuilder: (context, state) =>
          _fadeThroughPage(const ProgressAnalyticsScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen()),
    GoRoute(
      path: AppRoutes.resumeResult,
      builder: (context, state) => const ResumeAnalysisResultScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillAssessment,
      builder: (context, state) => const SkillAssessmentScreen(),
    ),
    GoRoute(
      path: AppRoutes.skillGapReport,
      builder: (context, state) => const SkillGapReportScreen(),
    ),
    GoRoute(
      path: AppRoutes.learningResources,
      builder: (context, state) => const LearningResourcesScreen(),
    ),
    GoRoute(
      path: AppRoutes.jobDetail,
      builder: (context, state) =>
          JobDetailScreen(jobId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: AppRoutes.aiMockInterview,
      pageBuilder: (context, state) =>
          _fadeThroughPage(const AiMockInterviewScreen()),
    ),
    // Bottom-nav tabs: each branch keeps its own navigation stack alive
    // when switching tabs (StatefulShellRoute.indexedStack semantics).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const HomeDashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.resumeUpload,
            builder: (context, state) => const ResumeUploadScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.careerRoadmap,
            builder: (context, state) => const CareerRoadmapScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.aiChatbot,
            builder: (context, state) => const AiChatbotScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.jobMatching,
            builder: (context, state) => const JobMatchingScreen(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: AppRoutes.premiumSubscription,
      builder: (context, state) => const PremiumSubscriptionScreen(),
    ),
    GoRoute(
      path: AppRoutes.paymentSuccess,
      builder: (context, state) => const PaymentStatusScreen(success: true),
    ),
    GoRoute(
      path: AppRoutes.paymentFailure,
      builder: (context, state) => const PaymentStatusScreen(success: false),
    ),
  ],
);
