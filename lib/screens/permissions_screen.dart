import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  final PermissionService _permissionService = PermissionService();
  bool _micGranted = false;
  bool _mediaGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.isGranted;

    // Para media, usamos la lógica del servicio o verificamos photos/storage
    // Simplificación: verificamos si photos o storage están concedidos para mostrar el switch activo
    bool mediaStatus = false;
    if (await Permission.photos.isGranted ||
        await Permission.storage.isGranted) {
      mediaStatus = true;
    }

    if (mounted) {
      setState(() {
        _micGranted = micStatus;
        _mediaGranted = mediaStatus;
      });
    }
  }

  Future<void> _handlePermissionChange(
    bool value,
    Function requestMethod,
  ) async {
    if (value) {
      // El usuario quiere activar
      await requestMethod();
    } else {
      // El usuario quiere desactivar -> Ir a configuración
      await _permissionService.openSettings();
    }
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Permisos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aquí puedes gestionar los permisos necesarios para el funcionamiento de la aplicación. '
                'Si deseas desactivar un permiso, serás redirigido a la configuración del sistema.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPermissionTile(
            title: 'Micrófono',
            subtitle: 'Necesario para registrar gastos por voz.',
            icon: Icons.mic,
            value: _micGranted,
            onChanged: (value) => _handlePermissionChange(
              value,
              _permissionService.requestMicrophonePermission,
            ),
          ),
          const Divider(),
          _buildPermissionTile(
            title: 'Multimedia / Galería',
            subtitle: 'Necesario para seleccionar imágenes de recibos.',
            icon: Icons.photo_library,
            value: _mediaGranted,
            onChanged: (value) => _handlePermissionChange(
              value,
              _permissionService.requestMediaPermission,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: value ? Colors.green.shade100 : Colors.grey.shade200,
        child: Icon(icon, color: value ? Colors.green : Colors.grey),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.green,
      ),
    );
  }
}
