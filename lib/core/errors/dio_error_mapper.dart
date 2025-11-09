import 'package:dio/dio.dart';

/// Tipos de error de red normalizados
enum NetworkErrorType {
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  timeout,
  noConnection,
  server,
  cancelled,
  unknown,
}

class NetworkError implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic raw;

  NetworkError(this.type, this.message, {this.statusCode, this.raw});

  @override
  String toString() => 'NetworkError(type: $type, code: $statusCode, message: $message)';
}

class DioErrorMapper {
  static NetworkError map(Object error) {
    if (error is NetworkError) return error;

    if (error is DioException) {
      final status = error.response?.statusCode;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return NetworkError(NetworkErrorType.timeout, 'Tiempo de espera agotado', statusCode: status, raw: error);
        case DioExceptionType.badCertificate:
          return NetworkError(NetworkErrorType.server, 'Certificado inválido', statusCode: status, raw: error);
        case DioExceptionType.connectionError:
          return NetworkError(NetworkErrorType.noConnection, 'Sin conexión al servidor', statusCode: status, raw: error);
        case DioExceptionType.cancel:
          return NetworkError(NetworkErrorType.cancelled, 'Solicitud cancelada', statusCode: status, raw: error);
        case DioExceptionType.unknown:
          // Revisamos si es un SocketException
          final msg = error.message ?? 'Error desconocido';
          return NetworkError(NetworkErrorType.unknown, msg, statusCode: status, raw: error);
        case DioExceptionType.badResponse:
          if (status != null) {
            if (status == 401) {
              return NetworkError(NetworkErrorType.unauthorized, 'No autorizado', statusCode: status, raw: error);
            } else if (status == 403) {
              return NetworkError(NetworkErrorType.forbidden, 'Acceso prohibido', statusCode: status, raw: error);
            } else if (status == 404) {
              return NetworkError(NetworkErrorType.notFound, 'Recurso no encontrado', statusCode: status, raw: error);
            } else if (status == 409) {
              return NetworkError(NetworkErrorType.conflict, 'Conflicto en la solicitud', statusCode: status, raw: error);
            } else if (status == 422 || status == 400) {
              return NetworkError(NetworkErrorType.validation, _extractValidationMessage(error.response?.data) ?? 'Datos inválidos', statusCode: status, raw: error);
            } else if (status >= 500) {
              return NetworkError(NetworkErrorType.server, 'Error interno del servidor', statusCode: status, raw: error);
            }
          }
          return NetworkError(NetworkErrorType.unknown, 'Error inesperado', statusCode: status, raw: error);
      }
    }

    return NetworkError(NetworkErrorType.unknown, 'Error desconocido', raw: error);
  }

  static String? _extractValidationMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      for (final key in ['message', 'error', 'detail']) {
        final v = data[key];
        if (v is String) return v;
        if (v is List && v.isNotEmpty) return v.first.toString();
      }
    }
    return null;
  }
}
