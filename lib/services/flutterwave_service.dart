/// Flutterwave payment service for card top-ups, mobile money, and bank transfers.

import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'api_client.dart';

class FlutterwaveService {
  static String? _publicKey;

  static Future<void> init() async {
    try {
      final config = await ApiClient.get('/v1/payment-config/flutterwave');
      _publicKey = config['public_key'];
    } catch (_) {}
  }

  /// Launch Flutterwave payment modal for wallet top-up
  static Future<Map<String, dynamic>?> topUp({
    required BuildContext context,
    required String email,
    required double amount,
    required String currency,
    required String name,
    required String phone,
  }) async {
    if (_publicKey == null) await init();
    if (_publicKey == null) throw Exception('Payment service unavailable');

    final txRef = 'nomads-topup-${DateTime.now().millisecondsSinceEpoch}';

    final customer = Customer(
      name: name,
      phoneNumber: phone,
      email: email,
    );

    final flutterwave = Flutterwave(
      publicKey: _publicKey!,
      currency: currency,
      redirectUrl: 'https://pay.nomads.one/wallet/callback',
      txRef: txRef,
      amount: amount.toStringAsFixed(2),
      customer: customer,
      paymentOptions: 'card,banktransfer,ussd,mobilemoney',
      customization: Customization(
        title: 'Pay Nomads Top-Up',
        description: 'Add $currency ${amount.toStringAsFixed(2)} to your wallet',
        logo: 'https://pay.nomads.one/favicon.png',
      ),
      isTestMode: false,
    );

    final response = await flutterwave.charge(context);

    if (response.status == 'successful') {
      // Verify on backend and credit wallet
      final verification = await ApiClient.post('/v1/topup/verify', {
        'tx_ref': txRef,
        'transaction_id': response.transactionId,
        'amount': amount,
        'currency': currency,
        'provider': 'flutterwave',
      });
      return verification;
    }

    return null;
  }

  /// Initiate payout via Flutterwave
  static Future<Map<String, dynamic>> payout({
    required int sourceAccountId,
    required double amount,
    required String currency,
    required String beneficiaryName,
    required String beneficiaryAccount,
    required String beneficiaryBank,
    required String countryCode,
    String? reference,
  }) async {
    return await ApiClient.post('/v1/payout/flutterwave', {
      'source_account_id': sourceAccountId,
      'amount': amount,
      'currency': currency,
      'beneficiary_name': beneficiaryName,
      'beneficiary_account': beneficiaryAccount,
      'beneficiary_bank': beneficiaryBank,
      'country_code': countryCode,
      'reference': reference,
    });
  }
}
