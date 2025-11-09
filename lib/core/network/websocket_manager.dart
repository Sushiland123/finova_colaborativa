import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import '../utils/logger.dart';

class WebSocketManager {
  late IO.Socket _socket;
  static final WebSocketManager _instance = WebSocketManager._internal();
  
  factory WebSocketManager() => _instance;
  
  WebSocketManager._internal();
  
  void initialize({String? token}) {
    _socket = IO.io(
      ApiConfig.websocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token ?? ''})
          .build(),
    );
    
    _setupEventListeners();
  }
  
  void _setupEventListeners() {
    _socket.onConnect((_) {
      AppLogger.info('🔌 WebSocket conectado');
    });
    
    _socket.onDisconnect((_) {
      AppLogger.info('❌ WebSocket desconectado');
    });
    
    _socket.onError((data) {
      AppLogger.error('⚠️ WebSocket error', data);
    });
    
    // Eventos personalizados para Finova
    _socket.on('transaction_update', (data) {
      AppLogger.debug('💰 Nueva transacción: $data');
      // TODO: Actualizar estado con Riverpod
    });
    
    _socket.on('group_update', (data) {
      AppLogger.debug('👥 Actualización de grupo: $data');
      // TODO: Actualizar estado con Riverpod
    });
    
    _socket.on('sync_required', (data) {
      AppLogger.debug('🔄 Sincronización requerida: $data');
      // TODO: Iniciar sincronización
    });
  }
  
  // Métodos para emitir eventos
  void emit(String event, dynamic data) {
    if (_socket.connected) {
      _socket.emit(event, data);
    } else {
      AppLogger.warning('Socket no conectado, no se pudo emitir: $event');
    }
  }
  
  // Suscribirse a eventos
  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }
  
  // Desconectar
  void disconnect() {
    _socket.disconnect();
  }
  
  // Reconectar
  void reconnect() {
    _socket.connect();
  }
  
  bool get isConnected => _socket.connected;
}