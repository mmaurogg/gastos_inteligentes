import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Solicita permiso para usar el micrófono.
  Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    } else {
      var result = await Permission.microphone.request();
      return result.isGranted;
    }
  }

  /// Solicita permisos para acceder a archivos multimedia (fotos/videos).
  /// Maneja las diferencias entre Android (Storage vs Media) e iOS (Photos).
  Future<bool> requestMediaPermission() async {
    if (Platform.isAndroid) {
      // Para Android 13+ (API 33+)
      // Se deben solicitar permisos granulares: photos, videos, audio.
      // permission_handler maneja esto con Permission.photos, Permission.videos, etc.
      // Pero verificamos la versión del SDK o intentamos solicitar ambos si es necesario.
      // Una estrategia común es solicitar 'photos' si solo queremos imágenes.

      // Verificamos si es Android 13 o superior indirectamente a través del comportamiento de permission_handler
      // o simplemente solicitamos lo que necesitamos.

      // Intentamos solicitar Photos (Android 13+ Images / iOS Photos)
      var photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) return true;

      // Intentamos solicitar Storage (Android < 13)
      var storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      // Si ninguno está concedido, solicitamos.
      // Nota: En Android 13+, solicitar 'storage' puede no hacer nada o devolver denied permanentemente.
      // Por eso es mejor intentar solicitar el adecuado.

      // Una forma robusta es solicitar ambos o usar un mapa de permisos.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
      ].request();

      return statuses[Permission.storage]!.isGranted ||
          statuses[Permission.photos]!.isGranted;
    } else {
      // iOS
      var status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      } else {
        var result = await Permission.photos.request();
        return result.isGranted;
      }
    }
  }

  /// Verifica si un permiso específico está concedido.
  Future<bool> checkPermission(Permission permission) async {
    return await permission.isGranted;
  }

  /// Abre la configuración de la aplicación si el usuario denegó permanentemente.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
