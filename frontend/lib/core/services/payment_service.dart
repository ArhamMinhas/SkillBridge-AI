import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../network/api_client.dart';

/// Wraps the Stripe PaymentSheet flow. The client only ever sees the
/// publishable key + ephemeral data returned by the backend — the secret
/// key never leaves FastAPI. See docs/frontend_design_spec.md section 9.
class PaymentService {
  final ApiClient _api = ApiClient.instance;

  Future<void> purchasePremium({required String plan}) async {
    final response = await _api
        .post('/payments/create-subscription-intent', data: {'plan': plan});
    final data = response.data as Map<String, dynamic>;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: data['clientSecret'] as String,
        customerId: data['customerId'] as String,
        customerEphemeralKeySecret: data['ephemeralKey'] as String,
        merchantDisplayName: 'SkillBridge AI',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  Future<void> cancelSubscription() {
    return _api.post('/payments/cancel-subscription');
  }
}
