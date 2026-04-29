import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/document_model.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class DocumentsState {
  const DocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });

  final List<DocumentModel> documents;
  final bool isLoading;
  final String? error;

  DocumentsState copyWith({
    List<DocumentModel>? documents,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      DocumentsState(
        documents: documents ?? this.documents,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  DocumentsNotifier(this._api, this._vehicleId)
      : super(const DocumentsState()) {
    loadDocuments();
  }

  final ApiService _api;
  final String _vehicleId;

  Future<void> loadDocuments() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final docs = await _api.getDocuments(_vehicleId);
      state = state.copyWith(documents: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents',
      );
    }
  }

  Future<bool> addDocument({
    required DocumentType documentType,
    required DateTime issueDate,
    required DateTime expirationDate,
  }) async {
    try {
      final doc = await _api.createDocument(_vehicleId, {
        'documentType': documentType.label,
        'issueDate': issueDate.toIso8601String().split('T').first,
        'expirationDate': expirationDate.toIso8601String().split('T').first,
      });
      state = state.copyWith(documents: [...state.documents, doc]);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to save document');
      return false;
    }
  }

  Future<bool> updateDocument(
    String docId, {
    required DateTime issueDate,
    required DateTime expirationDate,
  }) async {
    try {
      final updated = await _api.updateDocument(_vehicleId, docId, {
        'issueDate': issueDate.toIso8601String().split('T').first,
        'expirationDate': expirationDate.toIso8601String().split('T').first,
      });
      state = state.copyWith(
        documents: state.documents
            .map((d) => d.id == docId ? updated : d)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update document');
      return false;
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _api.deleteDocument(_vehicleId, docId);
      state = state.copyWith(
        documents: state.documents.where((d) => d.id != docId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete document');
    }
  }
}

// Scoped per vehicle — one provider family entry per vehicleId
final documentsProvider = StateNotifierProviderFamily<DocumentsNotifier,
    DocumentsState, String>(
  (ref, vehicleId) =>
      DocumentsNotifier(ref.read(apiServiceProvider), vehicleId),
);
