import 'package:flutter/material.dart';
import '../../../app/theme/tokens.dart';

class CodeStepWidget extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController portController;
  final TextEditingController codeController;
  final VoidCallback onPair;
  final bool isPairing;

  const CodeStepWidget({
    super.key,
    required this.ipController,
    required this.portController,
    required this.codeController,
    required this.onPair,
    this.isPairing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'On phone: Developer options → Wireless debugging → Pair with pairing code',
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.textMuted,
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
                  labelText: 'IP Address',
                  hintText: '192.168.1.xxx',
                ),
              ),
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: portController,
                decoration: const InputDecoration(
                  labelText: 'Pairing Port',
                  hintText: 'e.g. 38472',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space12),
        TextField(
          controller: codeController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '6-digit Pairing Code',
            hintText: '123456',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        ElevatedButton(
          onPressed: isPairing ? null : onPair,
          child: isPairing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pair & Connect'),
        ),
      ],
    );
  }
}
