/// Backend route paths, mirroring `app/main.py`'s `api_v1_prefix` +
/// `app/routes/*.py` registrations. Centralized so a backend path rename
/// only needs updating in one place on the Flutter side.
class ApiPaths {
  ApiPaths._();

  static const String _v1 = '/api/v1';

  static const String authMe = '$_v1/auth/me';

  static const String userProfile = '$_v1/users/profile';
  static const String dashboardStats = '$_v1/users/dashboard-stats';
  static const String progressAnalytics = '$_v1/users/progress-analytics';

  static const String jobs = '$_v1/jobs';
  static String jobDetail(String jobId) => '$_v1/jobs/$jobId';
  static String jobMatch(String jobId) => '$_v1/jobs/$jobId/match';

  static const String analyzeResume = '$_v1/ai/analyze-resume';
  static const String careerRoadmap = '$_v1/ai/career-roadmap';
  static const String interviewQuestions = '$_v1/ai/interview-questions';
  static const String mockInterviewAnswer = '$_v1/ai/mock-interview-answer';
  static const String chatbot = '$_v1/ai/chatbot';

  static const String skillScore = '$_v1/data-science/skill-score';
  static const String weakSkills = '$_v1/data-science/weak-skills';
  static const String jobMatchScore = '$_v1/data-science/job-match';
  static const String careerPathRecommendation =
      '$_v1/data-science/career-path-recommendation';
  static const String learningResourcesRecommendation =
      '$_v1/data-science/learning-resources-recommendation';
  static const String progressPrediction =
      '$_v1/data-science/progress-prediction';

  static const String createSubscriptionIntent =
      '$_v1/payments/create-subscription-intent';
  static const String cancelSubscription = '$_v1/payments/cancel-subscription';

  static const String adminAnalytics = '$_v1/admin/analytics';
  static const String adminUsers = '$_v1/admin/users';
}
