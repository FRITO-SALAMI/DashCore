import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:dashcore/models/bluetooth_enums.dart';
import 'package:dashcore/models/obd_device.dart';
import 'package:dashcore/providers/bluetooth_provider.dart';
import 'package:dashcore/utils/app_localizations.dart';

class BluetoothTab extends StatefulWidget {
  const BluetoothTab({super.key});

  @override
  State<BluetoothTab> createState() => _BluetoothTabState();
}

class _BluetoothTabState extends State<BluetoothTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BluetoothProvider>();
      if (!provider.isScanning && !provider.isConnected) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _handleScan();
        });
      }
    });
  }

  Future<void> _handleScan() async {
    final provider = context.read<BluetoothProvider>();
    final result = await provider.startScan();
    if (!mounted) return;
    if (result == BluetoothScanResult.permanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    final loc = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131315),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          loc.translate('bluetooth_required'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.translate('bluetooth_denied_msg'),
          style: const TextStyle(color: Colors.white54),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              loc.translate('cancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              loc.translate('open_settings'),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BluetoothScanStatusCard(onRefresh: _handleScan),
        const SizedBox(height: 12),
        Expanded(child: BluetoothDevicePanel(onScan: _handleScan)),
      ],
    );
  }
}

class BluetoothScanStatusCard extends StatelessWidget {
  final VoidCallback onRefresh;
  const BluetoothScanStatusCard({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isScanning = context.select<BluetoothProvider, bool>((provider) => provider.isScanning);
    final devicesCount = context.select<BluetoothProvider, int>((provider) => provider.discoveredDevices.length);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF131315),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isScanning ? null : onRefresh,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isScanning
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)))
                      : const Icon(Icons.bluetooth, color: Color(0xFF00E5FF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isScanning ? loc.translate('scanning') : loc.translate('scan_complete'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        isScanning ? loc.translate('searching_adapter') : loc.translate('found_devices', [devicesCount.toString()]),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!isScanning)
                  const Icon(Icons.refresh, color: Color(0xFF00E5FF), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BluetoothDevicePanel extends StatelessWidget {
  final VoidCallback onScan;
  const BluetoothDevicePanel({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131315),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            alignment: Alignment.center,
            child: const Text("DISPOSITIVOS DISPONIBLES (CLASSIC)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
          ),
          Expanded(child: BluetoothDeviceList(onScan: onScan)),
        ],
      ),
    );
  }
}

class BluetoothDeviceList extends StatelessWidget {
  final VoidCallback onScan;
  const BluetoothDeviceList({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Selector<BluetoothProvider, _BluetoothDeviceListState>(
      selector: (_, provider) => _BluetoothDeviceListState(
        isScanning: provider.isScanning,
        devices: List<ObdDevice>.of(provider.discoveredDevices),
      ),
      builder: (context, state, child) {
        if (state.devices.isEmpty && !state.isScanning) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 60, color: Colors.white10),
                const SizedBox(height: 10),
                Text(loc.translate('no_devices'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onScan,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: Text(loc.translate('start_scan'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.devices.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
          itemBuilder: (context, index) => BluetoothDeviceTile(device: state.devices[index]),
        );
      },
    );
  }
}

class BluetoothDeviceTile extends StatelessWidget {
  final ObdDevice device;
  const BluetoothDeviceTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final connectedAddress = context.select<BluetoothProvider, String?>((p) => p.connectedDevice?.address);
    final isConnected = connectedAddress == device.address;

    return ListTile(
      dense: true,
      onTap: isConnected ? null : () => _connectToAdapter(context, context.read<BluetoothProvider>(), device),
      leading: Icon(Icons.bluetooth, color: isConnected ? const Color(0xFF00E5FF) : Colors.white24, size: 20),
      title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(device.address, style: const TextStyle(color: Colors.white24, fontSize: 10)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isConnected ? loc.translate('connected') : loc.translate('available'),
            style: TextStyle(color: isConnected ? const Color(0xFF00E5FF) : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isConnected ? const Color(0xFF00E5FF) : Colors.transparent, border: Border.all(color: isConnected ? Colors.transparent : Colors.white10))),
        ],
      ),
    );
  }
}

Future<void> _connectToAdapter(BuildContext context, BluetoothProvider provider, ObdDevice device) async {
  final loc = AppLocalizations.of(context);
  bool isCanceled = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF131315),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF00E5FF)),
            const SizedBox(height: 24),
            Selector<BluetoothProvider, String>(
              selector: (_, p) => p.connectionMessage,
              builder: (context, msg, _) {
                String out = msg;
                if (msg.contains('CONNECTING TO')) {
                  out = loc.translate('connecting_to', [device.name]);
                } else if (msg == 'EXCHANGING DATA...') {
                  out = loc.translate('data_exchange');
                } else if (msg.contains('ATTEMPT')) {
                  out = loc.translate('attempt', [msg.split('#').last]);
                }
                return Text(out, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14));
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  isCanceled = true;
                  provider.cancelConnection();
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                child: Text(loc.translate('cancel'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  final success = await provider.connectToDevice(device);
  if (isCanceled || !context.mounted) return;
  
  if (Navigator.of(context).canPop()) {
     Navigator.of(context).pop();
  }

  if (!success && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('error_not_responding', [device.name])), backgroundColor: Colors.redAccent));
  }
}

class _BluetoothDeviceListState {
  final bool isScanning;
  final List<ObdDevice> devices;
  _BluetoothDeviceListState({required this.isScanning, required this.devices});
}
