import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/attachment_model.dart';
import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';

class AttachmentsState {
  const AttachmentsState({
    this.attachments = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AttachmentModel> attachments;
  final bool isLoading;
  final String? error;

  AttachmentsState copyWith({
    List<AttachmentModel>? attachments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AttachmentsState(
        attachments: attachments ?? this.attachments,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class AttachmentsNotifier extends StateNotifier<AttachmentsState> {
  AttachmentsNotifier(this._api, this._vehicleId)
      : super(const AttachmentsState()) {
    loadAttachments();
  }

  final ApiService _api;
  final String _vehicleId;

  Future<void> loadAttachments() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final attachments = await _api.getAttachments(_vehicleId);
      state = state.copyWith(attachments: attachments, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load files',
      );
    }
  }

  Future<bool> addAttachment({
    required File file,
    required AttachmentKind kind,
    DateTime? expirationDate,
    String? notes,
  }) async {
    try {
      final attachment = await _api.uploadAttachment(
        _vehicleId,
        file: file,
        kind: kind.apiValue,
        expirationDate:
            expirationDate?.toIso8601String().split('T').first,
        notes: notes,
      );
      state = state.copyWith(
        attachments: [attachment, ...state.attachments],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to upload file');
      return false;
    }
  }

  Future<void> removeAttachment(String attachmentId) async {
    try {
      await _api.deleteAttachment(_vehicleId, attachmentId);
      state = state.copyWith(
        attachments:
            state.attachments.where((a) => a.id != attachmentId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete file');
    }
  }
}

final attachmentsProvider = StateNotifierProvider.family<AttachmentsNotifier,
    AttachmentsState, String>(
  (ref, vehicleId) =>
      AttachmentsNotifier(ref.read(apiServiceProvider), vehicleId),
);
