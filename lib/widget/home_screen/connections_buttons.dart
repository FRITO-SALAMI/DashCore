import 'package:flutter/material.dart';

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
      height: isConnected ? 72.0 : 56.0,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: isConnected
                ? _buildConnectedState(key: const ValueKey('connected'))
                : _buildDisconnectedState(key: const ValueKey('disconnected')),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedState({required Key key}) {
    return Row(
      key: key,
      children: [
        const SizedBox(width: 16),
        const Icon(Icons.track_changes_rounded, color: Colors.black, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "CONNECTED",
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                "Vehicle is connected",
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDisconnectedState({required Key key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.tune_rounded, color: Colors.black, size: 24),
        SizedBox(width: 10),
        Text(
          "CONNECT",
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}
