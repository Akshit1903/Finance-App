import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';

class UploadDocument {
  final String id;
  final String title;
  final IconData icon;
  String? path;
  String? uploadedFileId;
  UploadStatus uploadStatus;

  UploadDocument({
    required this.id,
    required this.title,
    required this.icon,
    this.path,
    this.uploadedFileId,
    this.uploadStatus = UploadStatus.NOT_INITIATED,
  });

  void reset() {
    path = null;
    uploadedFileId = null;
    uploadStatus = UploadStatus.NOT_INITIATED;
  }

  bool get hasFile => path != null;
}
