import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/vehicle_model.dart';
import '../models/document_model.dart';

class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
        // Session cookie is sent automatically by the browser/WebView;
        // for native apps we persist and reattach it below.
        extra: {'withCredentials': true},
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onError: (err, handler) {
            // Surface DioExceptions with a readable message
            handler.next(err);
          },
        ),
      );
  }

  late final Dio _dio;

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (fullName != null) body['fullName'] = fullName;
    final res = await _dio.post(ApiConstants.register, data: body);
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
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() => _dio.post(ApiConstants.logout);

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get(ApiConstants.me);
    return res.data as Map<String, dynamic>;
  }

  // ── Vehicles ─────────────────────────────────────────────────

  Future<List<VehicleModel>> getVehicles() async {
    final res = await _dio.get(ApiConstants.vehicles);
    return (res.data as List)
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VehicleModel> createVehicle(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.vehicles, data: data);
    return VehicleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<VehicleModel> updateVehicle(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('${ApiConstants.vehicles}/$id', data: data);
    return VehicleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String id) =>
      _dio.delete('${ApiConstants.vehicles}/$id');

  // ── Documents ────────────────────────────────────────────────

  Future<List<DocumentModel>> getDocuments(String vehicleId) async {
    final res = await _dio.get(ApiConstants.documents(vehicleId));
    return (res.data as List)
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentModel> createDocument(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post(
      ApiConstants.documents(vehicleId),
      data: data,
    );
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
    return DocumentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(String vehicleId, String docId) =>
      _dio.delete(ApiConstants.document(vehicleId, docId));
}
