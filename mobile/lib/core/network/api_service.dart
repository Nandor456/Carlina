import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';
import '../models/attachment_model.dart';

class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (_token != null) {
              options.headers['Authorization'] = 'Bearer $_token';
            }
            handler.next(options);
          },
        ),
      );
  }

  late final Dio _dio;
  String? _token;

  void setToken(String? token) => _token = token;

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (fullName != null) body['fullName'] = fullName;
    final res = await _dio.post(ApiConstants.register, data: body);
    _ensureSuccess(res);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    _ensureSuccess(res);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final res = await _dio.post(
      ApiConstants.googleLogin,
      data: {'idToken': idToken},
    );
    _ensureSuccess(res);
    return res.data as Map<String, dynamic>;
  }

  /// Returns the current user, or null if not authenticated (401).
  Future<Map<String, dynamic>?> getMe() async {
    final res = await _dio.get(ApiConstants.me);
    if (res.statusCode == 401) return null;
    _ensureSuccess(res);
    return res.data as Map<String, dynamic>;
  }

  Future<void> registerFcmToken(String token) async {
    final res = await _dio.patch(
      ApiConstants.fcmToken,
      data: {'token': token},
    );
    if (res.statusCode == 401) return; // not yet authenticated — ignore
    _ensureSuccess(res);
  }

  // ── Vehicles ─────────────────────────────────────────────────

  Future<List<VehicleModel>> getVehicles() async {
    final res = await _dio.get(ApiConstants.vehicles);
    _ensureSuccess(res);
    return (res.data as List)
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.vehicles, data: data);
    _ensureSuccess(res);
    return VehicleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<VehicleModel> updateVehicle(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('${ApiConstants.vehicles}/$id', data: data);
    _ensureSuccess(res);
    return VehicleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String id) async {
    final res = await _dio.delete('${ApiConstants.vehicles}/$id');
    _ensureSuccess(res);
  }

  // ── Documents ────────────────────────────────────────────────

  Future<List<DocumentModel>> getDocuments(String vehicleId) async {
    final res = await _dio.get(ApiConstants.documents(vehicleId));
    _ensureSuccess(res);
    return (res.data as List)
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentModel> createDocument(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post(ApiConstants.documents(vehicleId), data: data);
    _ensureSuccess(res);
    return DocumentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DocumentModel> updateDocument(
    String vehicleId,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch(
      ApiConstants.document(vehicleId, docId),
      data: data,
    );
    _ensureSuccess(res);
    return DocumentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(String vehicleId, String docId) async {
    final res = await _dio.delete(ApiConstants.document(vehicleId, docId));
    _ensureSuccess(res);
  }

  // ── Vehicle image ────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadVehicleImage(
    String vehicleId,
    File file,
  ) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post(
      ApiConstants.vehicleImage(vehicleId),
      data: formData,
    );
    _ensureSuccess(res);
    return res.data as Map<String, dynamic>;
  }

  Future<Uint8List> fetchVehicleImage(String vehicleId) async {
    final res = await _dio.get<Uint8List>(
      ApiConstants.vehicleImage(vehicleId),
      options: Options(responseType: ResponseType.bytes),
    );
    if (res.statusCode == 404) return Uint8List(0);
    _ensureSuccess(res);
    return res.data ?? Uint8List(0);
  }

  Future<void> deleteVehicleImage(String vehicleId) async {
    final res = await _dio.delete(ApiConstants.vehicleImage(vehicleId));
    _ensureSuccess(res);
  }

  // ── Attachments ──────────────────────────────────────────────

  Future<List<AttachmentModel>> getAttachments(String vehicleId) async {
    final res = await _dio.get(ApiConstants.attachments(vehicleId));
    _ensureSuccess(res);
    return (res.data as List)
        .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AttachmentModel> uploadAttachment(
    String vehicleId, {
    required File file,
    required String kind,
    String? expirationDate,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'kind': kind,
      'expirationDate': ?expirationDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final res = await _dio.post(
      ApiConstants.attachments(vehicleId),
      data: formData,
    );
    _ensureSuccess(res);
    return AttachmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Uint8List> downloadAttachment(
    String vehicleId,
    String attachmentId,
  ) async {
    final res = await _dio.get<Uint8List>(
      ApiConstants.attachmentFile(vehicleId, attachmentId),
      options: Options(responseType: ResponseType.bytes),
    );
    _ensureSuccess(res);
    return res.data ?? Uint8List(0);
  }

  Future<void> deleteAttachment(String vehicleId, String attachmentId) async {
    final res = await _dio.delete(
      ApiConstants.attachment(vehicleId, attachmentId),
    );
    _ensureSuccess(res);
  }

  // ── Helpers ──────────────────────────────────────────────────

  void _ensureSuccess(Response<dynamic> res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = res.data;
    final message = body is Map && body['message'] is String
        ? body['message'] as String
        : 'Request failed (HTTP $code)';
    throw ApiException(code, message);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}
