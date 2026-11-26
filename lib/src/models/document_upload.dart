import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';

class UploadDocument {
  final String id;
  final String name;
  final String type;
  final String status; // "UPLOADED" or "PENDING"
  final String? uploadedFileId;
  final String? driveFolderId;
  final String? filePassword;

  // Runtime upload state
  String? path;
  UploadStatus uploadStatus;

  UploadDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.uploadedFileId,
    this.driveFolderId,
    this.filePassword,
    this.path,
    UploadStatus? uploadStatus,
  }) : uploadStatus = uploadStatus ??
            (status.toUpperCase() == 'UPLOADED'
                ? UploadStatus.SUCCESS
                : UploadStatus.NOT_INITIATED);

  factory UploadDocument.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String? ?? 'PENDING').toUpperCase();
    return UploadDocument(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: status,
      uploadedFileId: json['uploadedFileId'] as String?,
      driveFolderId: json['driveFolderId'] as String?,
      filePassword: json['filePassword'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'uploadedFileId': uploadedFileId,
      'driveFolderId': driveFolderId,
      'filePassword': filePassword,
    };
  }

  bool get isUploaded => status.toUpperCase() == 'UPLOADED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  String get title => name;

  IconData get icon {
    switch (type.toUpperCase()) {
      case 'SAVINGS_ACCOUNT_STATEMENT':
        return Icons.account_balance;
      case 'CREDIT_CARD_STATEMENT':
        return Icons.credit_card;
      case 'INCOME_STATEMENT':
        return Icons.receipt_long;
      default:
        return Icons.description;
    }
  }

  void reset() {
    path = null;
    uploadStatus = isUploaded ? UploadStatus.SUCCESS : UploadStatus.NOT_INITIATED;
  }

  bool get hasFile => path != null;
}

class DocumentUploadResponse {
  final bool stepCompleted;
  final List<UploadDocument> documents;

  const DocumentUploadResponse({
    required this.stepCompleted,
    required this.documents,
  });

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    final list = json['documents'] as List<dynamic>? ?? [];
    return DocumentUploadResponse(
      stepCompleted: json['stepCompleted'] as bool? ?? false,
      documents: list
          .map((item) => UploadDocument.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
