import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/widget/home_screen/connections_buttons.dart';
import 'package:dashcore/widget/connection/bluetooth/bluetooth_tab.dart';
import 'package:dashcore/widget/connection/bluetooth/bluetooth_waiting_widget.dart';
import 'package:dashcore/widget/connection/connection_screen/custom_tab_bar.dart';
import 'package:dashcore/utils/app_localizations.dart';
import 'package:dashcore/providers/dash_settings_provider.dart';

class ConnectionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ConnectionScreen({super.key, required this.onBack});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  ConnectionTab _selectedTab = ConnectionTab.bluetooth;
  bool _isBluetoothActivated = false;

  void _activateBluetooth() {
    setState(() {
      _isBluetoothActivated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final obdProvider = context.watch<ObdProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.translate('connection').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(
                    width: 220, // Increased width to fill more edge
                    height: 55, // Slightly taller
                    child: ConnectionButtons(
                      isConnected: obdProvider.isRealMode || obdProvider.isGpsMode,
                      onConnect: () async {
                        if (_selectedTab == ConnectionTab.gps) {
                           obdProvider.toggleGpsMode();
                        } else if (obdProvider.isDeviceConnected) {
                          obdProvider.toggleRealMode();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate('check_ignition')),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab Bar with BLUETOOTH / OBD and USB
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomTabBar(
                selectedTab: _selectedTab,
                onTabSelected: (tab) {
                  setState(() => _selectedTab = tab);
                },
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: _buildTabContent(colorScheme, loc, obdProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ColorScheme colorScheme, AppLocalizations loc, ObdProvider obd) {
    if (_selectedTab == ConnectionTab.gps) {
      return _buildGpsPlaceholder(obd);
    }

    return _isBluetoothActivated
        ? const BluetoothTab()
        : BluetoothWaitingWidget(onActivate: _activateBluetooth);
  }

  Widget _buildGpsPlaceholder(ObdProvider obd) {
    final isActive = obd.isGpsMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.location_on_rounded : Icons.location_off_rounded,
            size: 100,
            color: isActive ? const Color(0xFF00E5FF) : Colors.white10
          ),
          const SizedBox(height: 20),
          Text(
            isActive ? 'GPS ACTIVO' : 'MODO GPS DISPONIBLE',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            isActive ? 'OBTENIENDO VELOCIDAD VÍA SATÉLITE' : 'USA EL GPS SI NO TIENES ADAPTADOR OBD2',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.satellite_alt_rounded, color: Color(0xFF00E5FF), size: 24),
                      SizedBox(width: 15),
                      Text('ESTADO: ÓPTIMO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Precisión reforzada activada', style: TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
