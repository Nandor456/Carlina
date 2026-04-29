import 'document_model.dart';

class VehicleModel {
  const VehicleModel({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.make,
    required this.model,
    this.year,
    this.vin,
    this.documents = const [],
  });

  final String id;
  final String userId;
  final String licensePlate;
  final String make;
  final String model;
  final int? year;
  final String? vin;
  final List<DocumentModel> documents;

  /// The worst status among all documents (drives the card colour).
  DocumentStatus get overallStatus {
    if (documents.isEmpty) return DocumentStatus.active;
    if (documents.any((d) => d.status == DocumentStatus.expired)) {
      return DocumentStatus.expired;
    }
    if (documents.any((d) => d.status == DocumentStatus.expiringSoon)) {
      return DocumentStatus.expiringSoon;
    }
    return DocumentStatus.active;
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        licensePlate: json['licensePlate'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        year: json['year'] as int?,
        vin: json['vin'] as String?,
        documents: (json['documents'] as List<dynamic>? ?? [])
            .map((d) => DocumentModel.fromJson(d as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'licensePlate': licensePlate,
        'make': make,
        'model': model,
        if (year != null) 'year': year,
        if (vin != null) 'vin': vin,
      };

  VehicleModel copyWith({
    String? id,
    String? userId,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? vin,
    List<DocumentModel>? documents,
  }) =>
      VehicleModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        licensePlate: licensePlate ?? this.licensePlate,
        make: make ?? this.make,
        model: model ?? this.model,
        year: year ?? this.year,
        vin: vin ?? this.vin,
        documents: documents ?? this.documents,
      );
}
