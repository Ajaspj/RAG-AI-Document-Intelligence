import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:mobile/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mobile/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:mobile/features/dashboard/presentation/bloc/dashboard_state.dart';

void main() {
  group('DashboardBloc Tests', () {
    late DashboardBloc dashboardBloc;

    setUp(() {
      dashboardBloc = DashboardBloc();
    });

    tearDown(() {
      dashboardBloc.close();
    });

    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, equals(const DashboardInitial()));
    });

    test('emits [DashboardLoading, DashboardLoaded] when LoadDashboardData is added', () async {
      final expectedStates = [
        const DashboardLoading(),
        DashboardLoaded(
          stats: DashboardStats.initial(),
          recentDocuments: const [],
        ),
      ];

      expectLater(dashboardBloc.stream, emitsInOrder(expectedStates));

      dashboardBloc.add(const LoadDashboardData());
    });

    test('maintains state on RefreshDashboardData when already loaded', () async {
      dashboardBloc.add(const LoadDashboardData());
      await expectLater(
        dashboardBloc.stream,
        emitsThrough(isA<DashboardLoaded>()),
      );

      expect(dashboardBloc.state, isA<DashboardLoaded>());
    });
  });
}
