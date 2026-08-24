import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/providers/obd_provider.dart';
import 'package:dashcore/widget/home_screen/connections_buttons.dart';
import 'package:dashcore/widget/connection/bluetooth/bluetooth_tab.dart';
import 'package:dashcore/widget/connection/bluetooth/bluetooth_waiting_widget.dart';
import 'package:dashcore/widget/connection/connection_screen/custom_tab_bar.dart';
import 'package:dashcore/utils/app_localizations.dart';

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
            // HEADER - Compact
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
                        loc.translate('connection'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // CONNECT BUTTON - More compact
                  SizedBox(
                    width: 160,
                    height: 42,
                    child: ConnectionButtons(
                      isConnected: obdProvider.isRealMode,
                      onConnect: () async {
                        if (obdProvider.isDeviceConnected) {
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                child: _buildTabContent(colorScheme, loc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ColorScheme colorScheme, AppLocalizations loc) {
    return IndexedStack(
      index: _selectedTab.index,
      children: [
        _isBluetoothActivated
            ? const BluetoothTab()
            : BluetoothWaitingWidget(onActivate: _activateBluetooth),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.usb_rounded, size: 60, color: Colors.white12),
              const SizedBox(height: 20),
              Text(
                "${loc.translate('usb')} (In development)",
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
