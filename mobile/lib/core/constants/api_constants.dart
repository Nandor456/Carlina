import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class ApiConstants {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  // Google Sign-In client IDs loaded from mobile/.env.
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String googleLogin = '/auth/google';
  static const String fcmToken = '/auth/fcm-token';

  // Vehicles
  static const String vehicles = '/vehicles';

  // Documents — call with vehicleId
  static String documents(String vehicleId) => '/vehicles/$vehicleId/documents';
  static String document(String vehicleId, String docId) =>
      '/vehicles/$vehicleId/documents/$docId';

  // Vehicle image
  static String vehicleImage(String vehicleId) => '/vehicles/$vehicleId/image';

  // Attachments
  static String attachments(String vehicleId) =>
      '/vehicles/$vehicleId/attachments';
  static String attachment(String vehicleId, String attachmentId) =>
      '/vehicles/$vehicleId/attachments/$attachmentId';
  static String attachmentFile(String vehicleId, String attachmentId) =>
      '/vehicles/$vehicleId/attachments/$attachmentId/file';

  // Family
  static const String familyInvite = '/family/invite';
  static const String familyMembers = '/family/members';
  static const String familyInvitesReceived = '/family/invites/received';
  static const String familyInvitesSent = '/family/invites/sent';
  static String familyInviteAccept(String linkId) =>
      '/family/invites/$linkId/accept';
  static String familyInviteDecline(String linkId) =>
      '/family/invites/$linkId/decline';
  static String familyMember(String linkId) => '/family/members/$linkId';
  static String familyMemberVehicles(String memberId) =>
      '/family/members/$memberId/vehicles';
}
