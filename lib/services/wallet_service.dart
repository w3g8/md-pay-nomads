import 'api_client.dart';

class WalletService {
  Future<List<dynamic>> getAccounts() async {
    return await ApiClient.get('/v1/accounts') as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAccountBalance(int id) async {
    return await ApiClient.get('/v1/accounts/$id/balance');
  }

  Future<List<dynamic>> getTransactions(int accountId, {int limit = 20}) async {
    return await ApiClient.get('/v1/accounts/$accountId/transactions?limit=$limit');
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return await ApiClient.get('/v1/dashboard');
  }

  Future<List<dynamic>> getFXRates() async {
    return await ApiClient.get('/v1/exchange-rates');
  }

  Future<Map<String, dynamic>> createQRPayment({
    required int sourceAccountId,
    required String merchantName,
    required String merchantCity,
    required String merchantId,
    required String acquirerBic,
    required String mcc,
    required double amount,
    required String currency,
    required String paymentType,
    required String qrRawData,
  }) async {
    return await ApiClient.post('/v1/qr-payments', {
      'source_account_id': sourceAccountId,
      'merchant_name': merchantName,
      'merchant_city': merchantCity,
      'merchant_id': merchantId,
      'acquirer_bic': acquirerBic,
      'mcc': mcc,
      'amount': amount,
      'currency': currency,
      'payment_type': paymentType,
      'qr_raw_data': qrRawData,
    });
  }

  Future<Map<String, dynamic>> createTransfer({
    required int fromAccountId,
    required double amount,
    required String currency,
    String? reference,
    int? beneficiaryId,
  }) async {
    return await ApiClient.post('/v1/remittance', {
      'from_account_id': fromAccountId,
      'amount': amount,
      'currency': currency,
      if (reference != null) 'reference': reference,
      if (beneficiaryId != null) 'beneficiary_id': beneficiaryId,
    });
  }

  Future<List<dynamic>> getBeneficiaries() async {
    return await ApiClient.get('/v1/beneficiaries');
  }

  Future<List<dynamic>> getCards() async {
    return await ApiClient.get('/v1/cards');
  }

  Future<List<dynamic>> getQRPayments() async {
    return await ApiClient.get('/v1/qr-payments');
  }

  Future<List<dynamic>> getBillers({String? category}) async {
    final query = category != null ? '?category=$category' : '';
    return await ApiClient.get('/v1/billers$query') as List<dynamic>;
  }

  Future<List<dynamic>> getBillPayments({int limit = 10}) async {
    return await ApiClient.get('/v1/bill-payments?limit=$limit') as List<dynamic>;
  }

  Future<Map<String, dynamic>> payBill({
    required int sourceAccountId,
    required String billerCode,
    required String billerName,
    required String accountNumber,
    required double amount,
    required String category,
  }) async {
    return await ApiClient.post('/v1/bill-payments', {
      'source_account_id': sourceAccountId,
      'biller_code': billerCode,
      'biller_name': billerName,
      'account_number': accountNumber,
      'amount': amount,
      'category': category,
    });
  }

  Future<List<dynamic>> getPassportServices() async {
    return await ApiClient.get('/v1/passport-services') as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitPassportRenewal(Map<String, dynamic> data) async {
    return await ApiClient.post('/v1/passport-renewal', data);
  }

  Future<List<dynamic>> getVisaPrograms(String nationality) async {
    return await ApiClient.get('/v1/visa-programs?nationality=$nationality') as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitVisaApplication(Map<String, dynamic> data) async {
    return await ApiClient.post('/v1/visa-application', data);
  }

  Future<Map<String, dynamic>> getServiceStatus(String id) async {
    return await ApiClient.get('/v1/service-status/$id');
  }
}
