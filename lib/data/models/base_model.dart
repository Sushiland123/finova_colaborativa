import '../../core/sync/sync_manager.dart';

abstract class BaseModel {
  final String localId;        // ID local (UUID)
  final String? serverId;      // ID del servidor (null si no está sincronizado)
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? lastSyncAt;  // Última vez que se sincronizó
  
  BaseModel({
    required this.localId,
    this.serverId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncAt,
  });
  
  // Método para verificar si necesita sincronización
  bool get needsSync => syncStatus == SyncStatus.pending || syncStatus == SyncStatus.error;
  
  // Método para verificar si está sincronizado
  bool get isSynced => syncStatus == SyncStatus.synced && serverId != null;
}