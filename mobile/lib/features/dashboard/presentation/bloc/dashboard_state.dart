import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_document.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<RecentDocument> recentDocuments;

  const DashboardLoaded({required this.stats, this.recentDocuments = const []});

  @override
  List<Object?> get props => [stats, recentDocuments];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
