import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/placeholder_screen.dart';

class PaymentStatusScreen extends StatelessWidget {
  final bool success;

  const PaymentStatusScreen({super.key, required this.success});

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: success ? 'Payment Success' : 'Payment Failed',
        icon: success ? Icons.check_circle_rounded : Icons.error_rounded,
      );
}
