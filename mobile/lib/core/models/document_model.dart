enum DocumentType { rca, itp, rovinieta }

enum DocumentStatus { active, expiringSoon, expired }

extension DocumentTypeX on DocumentType {
  String get label => switch (this) {
        DocumentType.rca => 'RCA',
        DocumentType.itp => 'ITP',
        DocumentType.rovinieta => 'Rovinieta',
      };

  String get description => switch (this) {
        DocumentType.rca => 'Auto Liability Insurance',
        DocumentType.itp => 'Technical Inspection',
        DocumentType.rovinieta => 'Road Toll / Vignette',
      };

  static DocumentType fromString(String value) => switch (value.toUpperCase()) {
        'RCA' => DocumentType.rca,
        'ITP' => DocumentType.itp,
        'ROVINIETA' => DocumentType.rovinieta,
        _ => throw ArgumentError('Unknown document type: $value'),
      };
}

extension DocumentStatusX on DocumentStatus {
  static DocumentStatus fromString(String value) =>
      switch (value.toUpperCase()) {
        'ACTIVE' => DocumentStatus.active,
        'EXPIRING_SOON' => DocumentStatus.expiringSoon,
        'EXPIRED' => DocumentStatus.expired,
        _ => DocumentStatus.active,
      };
}

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.vehicleId,
    required this.documentType,
    required this.issueDate,
    required this.expirationDate,
    required this.status,
  });

  final String id;
  final String vehicleId;
  final DocumentType documentType;
  final DateTime issueDate;
  final DateTime expirationDate;
  final DocumentStatus status;

  /// Days remaining until expiry (negative = already expired).
  int get daysLeft {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final expiryNorm = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return expiryNorm.difference(todayNorm).inDays;
  }

  /// Fraction of the document's validity period that has elapsed [0.0 – 1.0].
  double get progressFraction {
    final total =
        expirationDate.difference(issueDate).inDays.toDouble();
    if (total <= 0) return 1.0;
    final elapsed =
        DateTime.now().difference(issueDate).inDays.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        documentType: DocumentTypeX.fromString(json['documentType'] as String),
        issueDate: DateTime.parse(json['issueDate'] as String),
        expirationDate: DateTime.parse(json['expirationDate'] as String),
        status: DocumentStatusX.fromString(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'documentType': documentType.label,
        'issueDate': issueDate.toIso8601String().split('T').first,
        'expirationDate':
            expirationDate.toIso8601String().split('T').first,
      };

  DocumentModel copyWith({
    String? id,
    String? vehicleId,
    DocumentType? documentType,
    DateTime? issueDate,
    DateTime? expirationDate,
    DocumentStatus? status,
  }) =>
      DocumentModel(
        id: id ?? this.id,
        vehicleId: vehicleId ?? this.vehicleId,
        documentType: documentType ?? this.documentType,
        issueDate: issueDate ?? this.issueDate,
        expirationDate: expirationDate ?? this.expirationDate,
        status: status ?? this.status,
      );
}
