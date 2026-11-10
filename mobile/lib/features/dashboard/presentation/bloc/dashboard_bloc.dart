import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/recent_document.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<UpdateDashboardFromDocuments>(_onUpdateDashboardFromDocuments);
  }

  void _onUpdateDashboardFromDocuments(
    UpdateDashboardFromDocuments event,
    Emitter<DashboardState> emit,
  ) {
    final docs = event.documents;
    final stats = DashboardStats(
      totalDocuments: docs.length,
      processedDocuments: docs.where((d) => d.isCompleted).length,
      failedDocuments: docs.where((d) => d.isFailed).length,
      totalQueries: 0,
    );
    final recentDocs = docs.take(5).map((d) => RecentDocument(
      id: d.id,
      name: d.filename,
      fileType: d.fileExtension,
      fileSize: d.formattedFileSize,
      uploadedAt: d.uploadedAt,
      status: d.status,
    )).toList();

    emit(DashboardLoaded(stats: stats, recentDocuments: recentDocs));
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      emit(
        DashboardLoaded(
          stats: DashboardStats.initial(),
          recentDocuments: const <RecentDocument>[],
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final currentStats = state is DashboardLoaded
          ? (state as DashboardLoaded).stats
          : DashboardStats.initial();
      final currentDocs = state is DashboardLoaded
          ? (state as DashboardLoaded).recentDocuments
          : const <RecentDocument>[];

      emit(DashboardLoaded(stats: currentStats, recentDocuments: currentDocs));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
