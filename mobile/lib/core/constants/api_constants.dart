abstract class ApiConstants {
  //static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String googleLogin = '/auth/google';

  // Vehicles
  static const String vehicles = '/vehicles';

  // Documents — call with vehicleId
  static String documents(String vehicleId) => '/vehicles/$vehicleId/documents';
  static String document(String vehicleId, String docId) =>
      '/vehicles/$vehicleId/documents/$docId';
}
