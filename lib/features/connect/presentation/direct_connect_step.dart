import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class DirectConnectStepWidget extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController portController;
  final VoidCallback onConnect;
  final bool isConnecting;

  const DirectConnectStepWidget({
    super.key,
    required this.ipController,
    required this.portController,
    required this.onConnect,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'For phones already paired with this PC or with Wireless debugging active.\nCheck the "IP address & Port" shown on your phone\'s Wireless debugging screen.',
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.textMuted,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.space16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'Phone IP Address',
                  hintText: '192.168.1.xxx',
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Connect Port',
                  hintText: 'e.g. 41235',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space20),
        ElevatedButton.icon(
          icon: isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link, size: 18),
          label: Text(isConnecting ? 'Connecting...' : 'Connect to Phone'),
          onPressed: isConnecting ? null : onConnect,
        ),
      ],
    );
  }
}
