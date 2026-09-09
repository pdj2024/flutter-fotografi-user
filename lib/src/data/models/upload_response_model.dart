class UploadResponseModel {
  final String uploadUrl;
  final String objectName;
  final DateTime expiredAt;

  UploadResponseModel({
    required this.uploadUrl,
    required this.objectName,
    required this.expiredAt,
  });

  /// FROM JSON
  factory UploadResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadResponseModel(
      uploadUrl: json['UploadUrl'] ?? "",
      objectName: json['ObjectName'] ?? "",
      expiredAt: DateTime.tryParse(json['ExpiredAt'] ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "UploadUrl": uploadUrl,
      "ObjectName": objectName,
      "ExpiredAt": expiredAt.toIso8601String(),
    };
  }

  /// COPYWITH
  UploadResponseModel copyWith({
    String? uploadUrl,
    String? objectName,
    DateTime? expiredAt,
  }) {
    return UploadResponseModel(
      uploadUrl: uploadUrl ?? this.uploadUrl,
      objectName: objectName ?? this.objectName,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }
}
