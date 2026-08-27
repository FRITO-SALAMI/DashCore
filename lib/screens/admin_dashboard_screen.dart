import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/admin_user_model.dart';
import '../services/supabase_service.dart';
import '../providers/dash_settings_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminDashboardScreen({super.key, required this.onBack});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<AdminUser> _users = [];
  AdminUser? _selectedUser;
  bool _showMap = true;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rawUsers = await SupabaseService.instance.getAdminUsers();

    setState(() {
      _users = rawUsers.map((u) => AdminUser.fromSupabase(u)).toList();
      _isLoading = false;
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    _markers.clear();
    for (final user in _users) {
      if (user.latitude != null && user.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(user.uuid),
            position: LatLng(user.latitude!, user.longitude!),
            infoWindow: InfoWindow(
              title: user.email ?? 'Usuario',
              snippet: 'Creado el: ${user.createdAt?.toString().split('.')[0] ?? 'Desconocido'}',
              onTap: () => setState(() => _selectedUser = user),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<DashSettingsProvider>().accentColor;

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: Row(
        children: [
          // Sidebar / User List
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(themeColor),
                Expanded(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUserList(themeColor),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Stack(
              children: [
                if (_showMap)
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 2,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    style: _darkMapStyle,
                  )
                else
                  const Center(child: Text('Vista de Análisis de Datos', style: TextStyle(color: Colors.white24))),

                if (_selectedUser != null)
                  _buildUserDetailOverlay(themeColor),

                _buildMapToggleControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                'ADMIN PANEL',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar usuario o UUID...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 18),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(Color themeColor) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isSelected = _selectedUser?.uuid == user.uuid;

        return InkWell(
          onTap: () => setState(() => _selectedUser = user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? themeColor.withOpacity(0.1) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? themeColor : Colors.transparent),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: themeColor.withOpacity(0.2),
                  child: Text(user.email?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email ?? 'Sin Email', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(user.uuid, style: const TextStyle(color: Colors.white24, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (user.latitude != null)
                  Icon(Icons.location_on_rounded, color: themeColor, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserDetailOverlay(Color themeColor) {
    final user = _selectedUser!;
    return Positioned(
      right: 20,
      top: 20,
      bottom: 20,
      width: 400,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30)],
        ),
        child: Column(
          children: [
            _buildDetailHeader(user, themeColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _infoGroup('IDENTIFICACIÓN', {
                    'UUID': user.uuid,
                    'Email': user.email ?? 'N/A',
                    'Estado': user.accountStatus,
                  }),
                  _infoGroup('ACCESO Y ACTIVIDAD', {
                    'Creado': user.createdAt?.toString() ?? 'N/A',
                    'Último Acceso': user.lastAccess?.toString() ?? 'N/A',
                    'Sesiones': '${user.sessionCount}',
                  }),
                  _infoGroup('CONECTIVIDAD', {
                    'IP Registro': user.registrationIp ?? 'N/A',
                    'Última IP': user.lastIp ?? 'N/A',
                    'País': user.country ?? 'N/A',
                    'Ciudad': '${user.city ?? 'N/A'}, ${user.region ?? ''}',
                    'Zona Horaria': user.timezone ?? 'N/A',
                  }),
                  _infoGroup('DISPOSITIVO', {
                    'Modelo': '${user.manufacturer ?? ''} ${user.model ?? ''}',
                    'Sistema': '${user.os ?? ''} ${user.osVersion ?? ''}',
                    'DashCore': user.dashCoreVersion ?? 'N/A',
                    'Idioma': user.language ?? 'N/A',
                  }),
                  _infoGroup('LOCALIZACIÓN GPS', {
                    'Coordenadas': user.latitude != null ? '${user.latitude}, ${user.longitude}' : 'No disponible',
                    'Fecha GPS': user.locationTimestamp?.toString() ?? 'N/A',
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(AdminUser user, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: themeColor, child: const Icon(Icons.person, color: Colors.black)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email ?? 'USUARIO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('PERFIL COMPLETO', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => setState(() => _selectedUser = null),
          ),
        ],
      ),
    );
  }

  Widget _infoGroup(String title, Map<String, String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(title, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 100, child: Text(e.key, style: const TextStyle(color: Colors.white38, fontSize: 12))),
              Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))),
            ],
          ),
        )).toList(),
        const Divider(color: Colors.white10, height: 32),
      ],
    );
  }

  Widget _buildMapToggleControls() {
    return Positioned(
      left: 20,
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            _mapControlButton(Icons.map_rounded, _showMap, () => setState(() => _showMap = true)),
            const SizedBox(width: 8),
            _mapControlButton(Icons.analytics_rounded, !_showMap, () => setState(() => _showMap = false)),
            const SizedBox(width: 16),
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white54), onPressed: _loadData),
          ],
        ),
      ),
    );
  }

  Widget _mapControlButton(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: active ? Colors.black : Colors.white54, size: 20),
      ),
    );
  }

  static const String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#212121" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#212121" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] }
]
''';
}
