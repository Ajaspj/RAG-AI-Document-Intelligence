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
import 'features/documents/data/datasources/document_remote_data_source.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/domain/usecases/delete_document.dart';
import 'features/documents/domain/usecases/get_documents.dart';
import 'features/documents/domain/usecases/pick_document.dart';
import 'features/documents/domain/usecases/retry_upload.dart';
import 'features/documents/domain/usecases/upload_document.dart';
import 'features/documents/presentation/bloc/documents_bloc.dart';

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

  final documentRemoteDataSource = DocumentRemoteDataSourceImpl(apiClient);
  final documentRepository = DocumentRepositoryImpl(
    remoteDataSource: documentRemoteDataSource,
  );
  final documentsBloc = DocumentsBloc(
    getDocumentsUseCase: GetDocumentsUseCase(documentRepository),
    pickDocumentUseCase: PickDocumentUseCase(documentRepository),
    uploadDocumentUseCase: UploadDocumentUseCase(documentRepository),
    deleteDocumentUseCase: DeleteDocumentUseCase(documentRepository),
    retryUploadUseCase: RetryUploadUseCase(documentRepository),
  );

  final router = AppRouter.createRouter(
    authBloc: authBloc,
    storageService: storageService,
  );

  runApp(
    DocumentIntelligenceApp(
      authBloc: authBloc,
      documentsBloc: documentsBloc,
      storageService: storageService,
      router: router,
    ),
  );
}

class DocumentIntelligenceApp extends StatelessWidget {
  final AuthBloc? authBloc;
  final DocumentsBloc? documentsBloc;
  final SecureStorageService? storageService;
  final GoRouter? router;

  const DocumentIntelligenceApp({
    super.key,
    this.authBloc,
    this.documentsBloc,
    this.storageService,
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStorageService = storageService ?? SecureStorageService();
    final effectiveApiClient = ApiClient(storageService: effectiveStorageService);
    final effectiveAuthDataSource = AuthRemoteDataSourceImpl(effectiveApiClient);
    final effectiveAuthRepo = AuthRepositoryImpl(
      remoteDataSource: effectiveAuthDataSource,
      storageService: effectiveStorageService,
    );

    final effectiveAuthBloc = authBloc ??
        AuthBloc(
          restoreSessionUseCase: RestoreSessionUseCase(effectiveAuthRepo),
          signInUseCase: SignInUseCase(effectiveAuthRepo),
          signUpUseCase: SignUpUseCase(effectiveAuthRepo),
          signOutUseCase: SignOutUseCase(effectiveAuthRepo),
          forgotPasswordUseCase: ForgotPasswordUseCase(effectiveAuthRepo),
          storageService: effectiveStorageService,
        );

    final effectiveDocDataSource = DocumentRemoteDataSourceImpl(effectiveApiClient);
    final effectiveDocRepo = DocumentRepositoryImpl(
      remoteDataSource: effectiveDocDataSource,
    );
    final effectiveDocumentsBloc = documentsBloc ??
        DocumentsBloc(
          getDocumentsUseCase: GetDocumentsUseCase(effectiveDocRepo),
          pickDocumentUseCase: PickDocumentUseCase(effectiveDocRepo),
          uploadDocumentUseCase: UploadDocumentUseCase(effectiveDocRepo),
          deleteDocumentUseCase: DeleteDocumentUseCase(effectiveDocRepo),
          retryUploadUseCase: RetryUploadUseCase(effectiveDocRepo),
        );

    final effectiveRouter = router ??
        AppRouter.createRouter(
          authBloc: effectiveAuthBloc,
          storageService: effectiveStorageService,
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: effectiveAuthBloc),
        BlocProvider<DocumentsBloc>.value(value: effectiveDocumentsBloc),
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
