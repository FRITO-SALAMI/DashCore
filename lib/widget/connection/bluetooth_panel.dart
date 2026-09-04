// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/bluetooth_provider.dart';
// import '../../models/obd_device.dart';

// class BluetoothPanel extends StatefulWidget {
//   const BluetoothPanel({super.key});

//   @override
//   State<BluetoothPanel> createState() => _BluetoothPanelState();
// }

// class _BluetoothPanelState extends State<BluetoothPanel> {
//   void _toggleBluetooth(BluetoothProvider provider) async {
//     if (!provider.isToggleOn) {
//       await provider.startScan();
//     } else {
//       provider.turnOffBluetooth();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bluetoothProvider = context.watch<BluetoothProvider>();
//     final isToggleOn = bluetoothProvider.isToggleOn;

//     return Container(
//       width: double.infinity,
//       constraints: const BoxConstraints(minHeight: 140),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(36),
//         color: Theme.of(context).colorScheme.surfaceContainer,
//         border: Border.all(
//           width: 2,
//           color: Theme.of(context).colorScheme.outlineVariant,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(34),
//         child: AnimatedSize(
//           duration: const Duration(milliseconds: 350),
//           curve: Curves.easeOutQuart,
//           alignment: Alignment.topCenter,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               SizedBox(
//                 height: 136,
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     onTap: () => _toggleBluetooth(bluetoothProvider),
//                     child: Padding(
//                       padding: const EdgeInsets.only(left: 36, right: 36),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               AnimatedDefaultTextStyle(
//                                 duration: const Duration(milliseconds: 170),
//                                 curve: Curves.easeInOut,
//                                 style: TextStyle(
//                                   fontSize: 28,
//                                   fontWeight: FontWeight.w800,
//                                   color: isToggleOn
//                                       ? Theme.of(context).colorScheme.primary
//                                       : Theme.of(context).colorScheme.onSurface,
//                                 ),
//                                 child: const Text(
//                                   "Bluetooth",
//                                   textScaler: TextScaler.noScaling,
//                                 ),
//                               ),
//                               Text(
//                                 textScaler: TextScaler.noScaling,
//                                 bluetoothProvider.isScanning
//                                     ? "Поиск устройств..."
//                                     : (isToggleOn
//                                           ? "Поиск завершен"
//                                           : "Нажмите для поиска"),
//                                 style: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.onSurface.withAlpha(150),
//                                   fontWeight: FontWeight.w800,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           AnimatedContainer(
//                             duration: const Duration(milliseconds: 200),
//                             curve: Curves.easeInOut,
//                             width: 75,
//                             height: 45,
//                             decoration: BoxDecoration(
//                               color: isToggleOn
//                                   ? Theme.of(context).colorScheme.primary
//                                   : Theme.of(
//                                       context,
//                                     ).colorScheme.outlineVariant,
//                               borderRadius: BorderRadius.circular(100),
//                             ),
//                             child: AnimatedAlign(
//                               duration: const Duration(milliseconds: 200),
//                               curve: Curves.easeInOut,
//                               alignment: isToggleOn
//                                   ? Alignment.centerRight
//                                   : Alignment.centerLeft,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                 ),
//                                 child: AnimatedContainer(
//                                   duration: const Duration(milliseconds: 220),
//                                   curve: Curves.easeInOut,
//                                   width: 30,
//                                   height: 30,
//                                   decoration: BoxDecoration(
//                                     color: isToggleOn
//                                         ? Theme.of(context).colorScheme.outline
//                                         : Theme.of(
//                                             context,
//                                           ).colorScheme.outline.withAlpha(100),
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               if (isToggleOn) ...[
//                 Divider(
//                   color: Theme.of(
//                     context,
//                   ).colorScheme.outlineVariant.withAlpha(100),
//                   height: 1,
//                   indent: 24,
//                   endIndent: 24,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(
//                     left: 16,
//                     right: 16,
//                     top: 8,
//                     bottom: 16,
//                   ),
//                   child: _buildPanelContent(bluetoothProvider),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPanelContent(BluetoothProvider provider) {
//     if (provider.isScanning && provider.discoveredDevices.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(24.0),
//         child: CircularProgressIndicator(),
//       );
//     } else if (!provider.isScanning && provider.discoveredDevices.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16.0),
//         child: Column(
//           children: [
//             Icon(
//               Icons.search_off_rounded,
//               size: 42,
//               color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Устройства не найдены",
//               textScaler: TextScaler.noScaling,
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
//             ),
//             const SizedBox(height: 4),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Text(
//                 "Убедитесь, что сканер подключен к разъему, а зажигание включено",
//                 textAlign: TextAlign.center,
//                 textScaler: TextScaler.noScaling,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => provider.startScan(),
//               icon: const Icon(Icons.refresh),
//               label: const Text(
//                 "Найти снова",
//                 textScaler: TextScaler.noScaling,
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Theme.of(context).colorScheme.primary,
//                 foregroundColor: Theme.of(context).colorScheme.onSurface,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(100),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       return Column(
//         children: [
//           ...provider.discoveredDevices.map((device) {
//             return _buildDeviceItem(device, provider);
//           }),
//           const SizedBox(height: 8),
//           _buildFooterRefreshButton(provider),
//         ],
//       );
//     }
//   }

//   Widget _buildDeviceItem(ObdDevice device, BluetoothProvider provider) {
//     bool isConnected = provider.connectedDevice?.address == device.address;

//     String statusText = isConnected ? "Подключено" : "Доступно";
//     Color bgColor = isConnected
//         ? Theme.of(context).colorScheme.primary
//         : Theme.of(context).colorScheme.outlineVariant.withAlpha(150);
//     Color textColor = isConnected
//         ? Colors.white
//         : Theme.of(context).colorScheme.onSurface.withAlpha(150);

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () async {
//           if (isConnected) return;

//           if (!provider.isConnecting) {
//             bool isCanceled = false;

//             showDialog(
//               context: context,
//               barrierDismissible: false,
//               builder: (dialogContext) {
//                 return PopScope(
//                   canPop: false,
//                   child: AlertDialog(
//                     insetPadding: const EdgeInsets.symmetric(horizontal: 60),
//                     backgroundColor: Theme.of(
//                       context,
//                     ).colorScheme.surfaceContainerHigh,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     contentPadding: EdgeInsets.zero,
//                     content: SizedBox(
//                       height: 220,
//                       child: Padding(
//                         padding: const EdgeInsets.all(24.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const SizedBox(
//                               width: 55,
//                               height: 55,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 4.5,
//                               ),
//                             ),
//                             Consumer<BluetoothProvider>(
//                               builder: (context, providerInstance, child) {
//                                 return Text(
//                                   providerInstance.connectionMessage,
//                                   textAlign: TextAlign.center,
//                                   textScaler: TextScaler.noScaling,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 14,
//                                   ),
//                                 );
//                               },
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.only(
//                                 left: 26,
//                                 right: 26,
//                                 bottom: 8,
//                               ),
//                               child: SizedBox(
//                                 width: double.infinity,
//                                 height: 40,
//                                 child: ElevatedButton(
//                                   onPressed: () {
//                                     isCanceled = true;
//                                     provider.cancelConnection();
//                                     Navigator.pop(dialogContext);
//                                   },
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Theme.of(
//                                       context,
//                                     ).colorScheme.primary,
//                                     foregroundColor: Theme.of(
//                                       context,
//                                     ).colorScheme.onSurface,
//                                     elevation: 0,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(100),
//                                     ),
//                                   ),
//                                   child: Text(
//                                     "Отмена",
//                                     textScaler: TextScaler.noScaling,
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       color: Theme.of(
//                                         context,
//                                       ).colorScheme.onSurface,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );

//             final success = await provider.connectToDevice(device);

//             if (!isCanceled && mounted) {
//               Navigator.pop(context);

//               if (!success) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text("Ошибка: '${device.name}' не отвечает"),
//                     backgroundColor: Theme.of(context).colorScheme.error,
//                   ),
//                 );
//               }
//             }
//           }
//         },
//         borderRadius: BorderRadius.circular(50),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Text(
//                   device.name,
//                   textScaler: TextScaler.noScaling,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w800,
//                     color: isConnected
//                         ? Theme.of(context).colorScheme.primary
//                         : Theme.of(context).colorScheme.onSurface,
//                   ),
//                 ),
//               ),
//               AnimatedSize(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeInOut,
//                 child: AnimatedContainer(
//                   alignment: Alignment.center,
//                   width: isConnected ? 120 : 110,
//                   duration: const Duration(milliseconds: 250),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     borderRadius: BorderRadius.circular(100),
//                   ),
//                   child: Text(
//                     statusText,
//                     textScaler: TextScaler.noScaling,
//                     style: TextStyle(
//                       color: textColor,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFooterRefreshButton(BluetoothProvider provider) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: provider.isScanning ? null : () => provider.startScan(),
//         borderRadius: BorderRadius.circular(100),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             color: Theme.of(
//               context,
//             ).colorScheme.surfaceContainerHighest.withAlpha(80),
//             borderRadius: BorderRadius.circular(100),
//             border: Border.all(
//               color: Theme.of(
//                 context,
//               ).colorScheme.outlineVariant.withAlpha(100),
//             ),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               if (provider.isScanning)
//                 const SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               else
//                 Icon(
//                   Icons.refresh,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               const SizedBox(width: 8),
//               Text(
//                 provider.isScanning ? "Обновление..." : "Обновить список",
//                 textScaler: TextScaler.noScaling,
//                 style: TextStyle(
//                   color: provider.isScanning
//                       ? Theme.of(context).colorScheme.onSurface
//                       : Theme.of(context).colorScheme.primary,
//                   fontWeight: FontWeight.w800,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
