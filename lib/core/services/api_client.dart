import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});

class ApiClient {
  late final Dio _dio;
  final AuthService _authService;

  ApiClient(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: aggiunge JWT a ogni richiesta
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Token scaduto → redirect al login
        if (e.response?.statusCode == 401) {
          await _authService.deleteToken();
        }

        // Gestione centralizzata degli errori di rete
        String errorMessage = 'Si è verificato un errore imprevisto.';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connessione al server scaduta. Riprova.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Impossibile connettersi al server. Verifica la tua connessione internet.';
        } else if (e.response == null) {
          errorMessage = 'Errore di rete. Controlla la tua connessione.';
        } else {
          return handler.next(e);
        }

        final customException = DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: e.error,
          message: errorMessage,
        );
        return handler.next(customException);
      },
    ));
  }

  Dio get dio => _dio;
}