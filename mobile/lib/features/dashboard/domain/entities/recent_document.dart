import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class RecentDocument extends Equatable {
  final String id;
  final String name;
  final String fileType; // pdf, docx, txt
  final String fileSize; // formatted e.g. "1.2 MB"
  final DateTime uploadedAt;
  final DocumentStatus status;
  final int? chunkCount;

  const RecentDocument({
    required this.id,
    required this.name,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    required this.status,
    this.chunkCount,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    fileType,
    fileSize,
    uploadedAt,
    status,
    chunkCount,
  ];
}
