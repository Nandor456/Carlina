enum AttachmentKind { insurance, registration, vignette, inspection, other }

extension AttachmentKindX on AttachmentKind {
  String get label => switch (this) {
        AttachmentKind.insurance => 'Insurance',
        AttachmentKind.registration => 'Registration',
        AttachmentKind.vignette => 'Vignette',
        AttachmentKind.inspection => 'Inspection',
        AttachmentKind.other => 'Other',
      };

  String get apiValue => switch (this) {
        AttachmentKind.insurance => 'INSURANCE',
        AttachmentKind.registration => 'REGISTRATION',
        AttachmentKind.vignette => 'VIGNETTE',
        AttachmentKind.inspection => 'INSPECTION',
        AttachmentKind.other => 'OTHER',
      };

  static AttachmentKind fromString(String value) =>
      switch (value.toUpperCase()) {
        'INSURANCE' => AttachmentKind.insurance,
        'REGISTRATION' => AttachmentKind.registration,
        'VIGNETTE' => AttachmentKind.vignette,
        'INSPECTION' => AttachmentKind.inspection,
        _ => AttachmentKind.other,
      };
}

class AttachmentModel {
  const AttachmentModel({
    required this.id,
    required this.vehicleId,
    required this.kind,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    this.expirationDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String vehicleId;
  final AttachmentKind kind;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final DateTime? expirationDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) => AttachmentModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        kind: AttachmentKindX.fromString(json['kind'] as String),
        originalFilename: json['originalFilename'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: json['sizeBytes'] as int,
        expirationDate: json['expirationDate'] != null
            ? DateTime.parse(json['expirationDate'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  AttachmentModel copyWith({
    String? id,
    String? vehicleId,
    AttachmentKind? kind,
    String? originalFilename,
    String? mimeType,
    int? sizeBytes,
    DateTime? expirationDate,
    bool clearExpiry = false,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AttachmentModel(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        kind: kind ?? this.kind,
        originalFilename: originalFilename ?? this.originalFilename,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        expirationDate: clearExpiry ? null : (expirationDate ?? this.expirationDate),
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
