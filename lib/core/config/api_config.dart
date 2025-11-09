import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Desarrollo local (host)
  static const String _baseUrlLocalhost = 'http://localhost:3000/api/v1';
  static const String _wsLocalhost = 'ws://localhost:3000';

  // Desarrollo en emulador Android (host -> emulador)
  // 10.0.2.2 apunta al localhost de la máquina desde el emulador Android
  static const String _baseUrlAndroidEmu = 'http://10.0.2.2:3000/api/v1';
  static const String _wsAndroidEmu = 'ws://10.0.2.2:3000';

  // Producción (cuando despliegues)
  static const String baseUrlProd = 'https://tu-api.com/api/v1';
  static const String websocketUrlProd = 'wss://tu-api.com';

  // Resolvedores dinámicos por plataforma
  static String get baseUrl {
    if (kIsWeb) return _baseUrlLocalhost; // Web apunta a localhost
    if (Platform.isAndroid) return _baseUrlAndroidEmu; // Emulador Android
    return _baseUrlLocalhost; // iOS simulator/desktop usan localhost
  }

  static String get websocketUrl {
    if (kIsWeb) return _wsLocalhost;
    if (Platform.isAndroid) return _wsAndroidEmu;
    return _wsLocalhost;
  }

  // Timeouts
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000;

  // Headers por defecto
  static Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}