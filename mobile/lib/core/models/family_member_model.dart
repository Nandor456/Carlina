class FamilyMemberModel {
  const FamilyMemberModel({
    required this.linkId,
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  final String linkId;
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      FamilyMemberModel(
        linkId: json['linkId'] as String,
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
