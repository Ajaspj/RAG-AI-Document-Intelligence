import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalDocuments;
  final int processedDocuments;
  final int failedDocuments;
  final int totalQueries;

  const DashboardStats({
    required this.totalDocuments,
    required this.processedDocuments,
    required this.failedDocuments,
    required this.totalQueries,
  });

  factory DashboardStats.initial() {
    return const DashboardStats(
      totalDocuments: 0,
      processedDocuments: 0,
      failedDocuments: 0,
      totalQueries: 0,
    );
  }

  DashboardStats copyWith({
    int? totalDocuments,
    int? processedDocuments,
    int? failedDocuments,
    int? totalQueries,
  }) {
    return DashboardStats(
      totalDocuments: totalDocuments ?? this.totalDocuments,
      processedDocuments: processedDocuments ?? this.processedDocuments,
      failedDocuments: failedDocuments ?? this.failedDocuments,
      totalQueries: totalQueries ?? this.totalQueries,
    );
  }

  @override
  List<Object?> get props => [
        totalDocuments,
        processedDocuments,
        failedDocuments,
        totalQueries,
      ];
}

