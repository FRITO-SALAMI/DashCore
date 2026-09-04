import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';

class ConnectionButtons extends StatelessWidget {
  final VoidCallback onConnect;
  final bool isConnected;

  const ConnectionButtons({
    super.key,
    required this.onConnect,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _AnimatedConnectButton(
          isConnected: isConnected,
          onPressed: onConnect,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _AnimatedConnectButton extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  const _AnimatedConnectButton({
    required this.isConnected,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      height: 50.0, // Increased height from 42.0
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(15), // More rounded
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isConnected
                ? _buildConnectedState(context, key: const ValueKey('connected'))
                : _buildDisconnectedState(context, key: const ValueKey('disconnected')),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedState(BuildContext context, {required Key key}) {
    final loc = AppLocalizations.of(context);
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.black, size: 22), // Larger icon
        const SizedBox(width: 10),
        Text(
          loc.translate('connected').toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14, // Larger font
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedState(BuildContext context, {required Key key}) {
    final loc = AppLocalizations.of(context);
    final isSpanish = loc.language.name == 'spanish';
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.bolt_rounded, color: Colors.black, size: 22), // Larger icon
        const SizedBox(width: 8),
        Text(
          isSpanish ? "CONECTAR" : "CONNECT",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14, // Larger font
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
