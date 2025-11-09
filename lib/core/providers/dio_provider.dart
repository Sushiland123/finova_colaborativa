import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';

/// Proveedor de DioClient como singleton compartido
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
