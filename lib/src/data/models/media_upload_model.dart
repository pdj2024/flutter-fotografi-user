class MediaUploadModel {
  final String? idKategori;
  final String uploaderId;
  final String fileName;
  final String objectName;
  final int originalSize;
  final String contentType;
  final bool? isSuccess;
  final String? errorMessage;

  MediaUploadModel({
    required this.idKategori,
    required this.uploaderId,
    required this.fileName,
    required this.objectName,
    required this.originalSize,
    required this.contentType,
    this.isSuccess,
    this.errorMessage,
  });

  /// FROM JSON
  factory MediaUploadModel.fromJson(Map<String, dynamic> json) {
    return MediaUploadModel(
      idKategori: json['id_kategori'],
      uploaderId: json['uploader_id'] ?? '',
      fileName: json['fileName'] ?? '',
      objectName: json['objectName'] ?? '',
      originalSize: json['original_size'] ?? 0,
      contentType: json['content_type'] ?? '',
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "id_kategori": idKategori,
      "uploader_id": uploaderId,
      "fileName": fileName,
      "objectName": objectName,
      "original_size": originalSize,
      "content_type": contentType,
    };
  }

  /// COPYWITH
  MediaUploadModel copyWith({
    String? idKategori,
    String? uploaderId,
    String? fileName,
    String? objectName,
    int? originalSize,
    String? contentType,
  }) {
    return MediaUploadModel(
      idKategori: idKategori ?? this.idKategori,
      uploaderId: uploaderId ?? this.uploaderId,
      fileName: fileName ?? this.fileName,
      objectName: objectName ?? this.objectName,
      originalSize: originalSize ?? this.originalSize,
      contentType: contentType ?? this.contentType,
    );
  }
}
