import 'package:equatable/equatable.dart';

import '../../../documents/domain/entities/document.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {
  const LoadDashboardData();
}

class RefreshDashboardData extends DashboardEvent {
  const RefreshDashboardData();
}

class UpdateDashboardFromDocuments extends DashboardEvent {
  final List<Document> documents;

  const UpdateDashboardFromDocuments(this.documents);

  @override
  List<Object?> get props => [documents];
}

