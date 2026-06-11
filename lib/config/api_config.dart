class ApiConfig {
  // Set to cloud URL by default, or pass via --dart-define=API_BASE_URL=http://localhost:5000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://smart-mess-backend-iv7g.onrender.com' // Replace with your Render URL (e.g. 'https://smart-mess-backend.onrender.com') when deployed
  );

  // Auth
  static const String signupStudent    = '$baseUrl/api/auth/signup/student';
  static const String signupAdmin      = '$baseUrl/api/auth/signup/admin';
  static const String login            = '$baseUrl/api/auth/login';
  static const String biometricLogin   = '$baseUrl/api/auth/biometric-login';
  static const String me               = '$baseUrl/api/auth/me';
  static const String updateProfile    = '$baseUrl/api/auth/profile';
  static const String changePassword   = '$baseUrl/api/auth/change-password';
  static const String biometricEnable  = '$baseUrl/api/auth/biometric-enable';

  // Mess
  static const String messSearch       = '$baseUrl/api/mess/search';
  static const String joinRequest      = '$baseUrl/api/mess/join-request';
  static const String myRequest        = '$baseUrl/api/mess/my-request';
  static const String messRequests     = '$baseUrl/api/mess/requests';
  static const String messStudents     = '$baseUrl/api/mess/students';
  static const String myMess           = '$baseUrl/api/mess/my-mess';
  static String approveRequest(String id) => '$baseUrl/api/mess/requests/$id/approve';
  static String rejectRequest(String id)  => '$baseUrl/api/mess/requests/$id/reject';
  static String removeStudent(String id)  => '$baseUrl/api/mess/students/$id';

  // Polls
  static const String polls            = '$baseUrl/api/polls';
  static const String activePolls      = '$baseUrl/api/polls/active';
  static const String pollHistory      = '$baseUrl/api/polls/history';
  static const String adminPolls       = '$baseUrl/api/polls/admin/all';
  static String pollById(String id)    => '$baseUrl/api/polls/$id';
  static String finalizePoll(String id)=> '$baseUrl/api/polls/$id/finalize';

  // Votes
  static const String votes            = '$baseUrl/api/votes';
  static const String myVote           = '$baseUrl/api/votes/my';
  static String pollVotes(String id)   => '$baseUrl/api/votes/poll/$id';

  // Feedback
  static const String feedback         = '$baseUrl/api/feedback';
  static const String feedbackSummary  = '$baseUrl/api/feedback/summary';
  static const String feedbackMess     = '$baseUrl/api/feedback/mess';
  static String feedbackStatus(String pollId) => '$baseUrl/api/feedback/my-status/$pollId';

  // Kitchen Orders
  static const String kitchenOrders   = '$baseUrl/api/kitchen-orders';

  // Notifications
  static const String notifications   = '$baseUrl/api/notifications';
  static const String notifCount      = '$baseUrl/api/notifications/count';
  static const String readAllNotifs   = '$baseUrl/api/notifications/read-all';
  static String readNotif(String id)  => '$baseUrl/api/notifications/$id/read';

  // Announcements
  static const String announcements         = '$baseUrl/api/announcements';
  static const String adminAnnouncements    = '$baseUrl/api/announcements/admin';
  static String deleteAnnouncement(String id) => '$baseUrl/api/announcements/$id';

  // Attendance
  static const String myAttendance      = '$baseUrl/api/attendance/my';
  static const String attendanceSummary = '$baseUrl/api/attendance/summary';
  static const String studentsAttendance= '$baseUrl/api/attendance/students';
  static const String attendanceAnalytics = '$baseUrl/api/attendance/analytics';
  static String studentAttendance(String id) => '$baseUrl/api/attendance/student/$id';
}