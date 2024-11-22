class Session {
  static int? currentUserId;

  static void login(int userId) {
    currentUserId = userId;
  }

  static void logout() {
    currentUserId = null;
  }

  static bool isLoggedIn() {
    return currentUserId != null;
  }
}
