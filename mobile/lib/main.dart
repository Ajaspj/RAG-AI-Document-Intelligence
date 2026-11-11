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
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/documents/data/datasources/document_remote_data_source.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/domain/usecases/delete_document.dart';
import 'features/documents/domain/usecases/get_documents.dart';
import 'features/documents/domain/usecases/pick_document.dart';
import 'features/documents/domain/usecases/retry_upload.dart';
import 'features/documents/domain/usecases/upload_document.dart';
import 'features/documents/presentation/bloc/documents_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = SecureStorageService();
  final apiClient = await ApiClient.create(storageService: storageService);
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

  final chatRemoteDataSource = ChatRemoteDataSourceImpl(apiClient);
  final chatRepository = ChatRepositoryImpl(remoteDataSource: chatRemoteDataSource);
  final chatBloc = ChatBloc(chatRepository: chatRepository);

  final router = AppRouter.createRouter(
    authBloc: authBloc,
    storageService: storageService,
  );

  runApp(
    DocumentIntelligenceApp(
      apiClient: apiClient,
      authBloc: authBloc,
      documentsBloc: documentsBloc,
      chatBloc: chatBloc,
      storageService: storageService,
      router: router,
    ),
  );
}

class DocumentIntelligenceApp extends StatelessWidget {
  final ApiClient? apiClient;
  final AuthBloc? authBloc;
  final DocumentsBloc? documentsBloc;
  final ChatBloc? chatBloc;
  final SecureStorageService? storageService;
  final GoRouter? router;

  const DocumentIntelligenceApp({
    super.key,
    this.apiClient,
    this.authBloc,
    this.documentsBloc,
    this.chatBloc,
    this.storageService,
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStorageService = storageService ?? SecureStorageService();
    final effectiveApiClient =
        apiClient ?? ApiClient(storageService: effectiveStorageService);
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

    final effectiveChatDataSource = ChatRemoteDataSourceImpl(effectiveApiClient);
    final effectiveChatRepo = ChatRepositoryImpl(remoteDataSource: effectiveChatDataSource);
    final effectiveChatBloc = chatBloc ?? ChatBloc(chatRepository: effectiveChatRepo);

    final effectiveRouter = router ??
        AppRouter.createRouter(
          authBloc: effectiveAuthBloc,
          storageService: effectiveStorageService,
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: effectiveAuthBloc),
        BlocProvider<DocumentsBloc>.value(value: effectiveDocumentsBloc),
        BlocProvider<ChatBloc>.value(value: effectiveChatBloc),
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
