import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/pairing/qr_payload.dart';

class QrStepWidget extends StatelessWidget {
  final QrPayload payload;
  final bool isPairing;

  const QrStepWidget({
    super.key,
    required this.payload,
    this.isPairing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: QrImageView(
            data: payload.payloadString,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        if (isPairing) ...[
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppTokens.space8),
              Text(
                'Pairing with detected phone...',
                style: TextStyle(
                  color: AppTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            'Waiting for phone to scan...',
            style: TextStyle(
              color: AppTokens.textMuted,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: AppTokens.space12),
        const Text(
          'On phone: Developer options → Wireless debugging → Pair with QR code',
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
