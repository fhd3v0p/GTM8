class PhotoUploadModel {
  final String id;
  final String userId;
  final String category;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final DateTime uploadDate;
  final String? description;

  PhotoUploadModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.uploadDate,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'fileId': fileId,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'uploadDate': uploadDate.toIso8601String(),
      'description': description,
    };
  }

  factory PhotoUploadModel.fromJson(Map<String, dynamic> json) {
    return PhotoUploadModel(
      id: json['id'],
      userId: json['userId'],
      category: json['category'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      uploadDate: DateTime.parse(json['uploadDate']),
      description: json['description'],
    );
  }
} 