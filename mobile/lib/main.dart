import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/forgot_password.dart';
import 'features/auth/domain/usecases/restore_session.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final apiClient = ApiClient(storageService: storageService);
  final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );

  final authBloc = AuthBloc(
    restoreSessionUseCase: RestoreSessionUseCase(authRepository),
    signInUseCase: SignInUseCase(authRepository),
    signUpUseCase: SignUpUseCase(authRepository),
    signOutUseCase: SignOutUseCase(authRepository),
    forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
    storageService: storageService,
  );

  final router = AppRouter.createRouter(
    authBloc: authBloc,
    storageService: storageService,
  );

  runApp(
    DocumentIntelligenceApp(
      authBloc: authBloc,
      storageService: storageService,
      router: router,
    ),
  );
}

class DocumentIntelligenceApp extends StatelessWidget {
  final AuthBloc? authBloc;
  final SecureStorageService? storageService;
  final GoRouter? router;

  const DocumentIntelligenceApp({
    super.key,
    this.authBloc,
    this.storageService,
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStorageService = storageService ?? SecureStorageService();
    final effectiveApiClient = ApiClient(storageService: effectiveStorageService);
    final effectiveDataSource = AuthRemoteDataSourceImpl(effectiveApiClient);
    final effectiveRepo = AuthRepositoryImpl(
      remoteDataSource: effectiveDataSource,
      storageService: effectiveStorageService,
    );

    final effectiveAuthBloc = authBloc ??
        AuthBloc(
          restoreSessionUseCase: RestoreSessionUseCase(effectiveRepo),
          signInUseCase: SignInUseCase(effectiveRepo),
          signUpUseCase: SignUpUseCase(effectiveRepo),
          signOutUseCase: SignOutUseCase(effectiveRepo),
          forgotPasswordUseCase: ForgotPasswordUseCase(effectiveRepo),
          storageService: effectiveStorageService,
        );

    final effectiveRouter = router ??
        AppRouter.createRouter(
          authBloc: effectiveAuthBloc,
          storageService: effectiveStorageService,
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: effectiveAuthBloc),
      ],
      child: MaterialApp.router(
        title: 'DocuMind AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: effectiveRouter,
      ),
    );
  }
}
