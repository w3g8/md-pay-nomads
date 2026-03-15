import 'package:flutter/material.dart';
import '../services/flutterwave_service.dart';
import '../services/wallet_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountCtrl = TextEditingController();
  String _currency = 'USD';
  bool _loading = false;
  String? _error;
  String? _success;
  List<dynamic> _accounts = [];
  int? _selectedAccountId;

  final _currencies = ['USD', 'EUR', 'GBP', 'PHP', 'THB', 'IDR', 'BRL', 'SGD', 'MYR', 'VND'];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await WalletService().getAccounts();
      if (_accounts.isNotEmpty) {
        _selectedAccountId = _accounts.first['id'];
        _currency = _accounts.first['currency'] ?? 'USD';
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _topUp() async {
    if (_amountCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; _success = null; });

    try {
      final result = await FlutterwaveService.topUp(
        context: context,
        email: 'user@nomads.one', // TODO: get from auth
        amount: double.parse(_amountCtrl.text),
        currency: _currency,
        name: 'Nomads User',
        phone: '',
      );

      if (result != null) {
        setState(() => _success = 'Top-up successful! $_currency ${_amountCtrl.text} added to your wallet.');
        _amountCtrl.clear();
      } else {
        setState(() => _error = 'Payment was cancelled or failed.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
              ),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Text(_success!, style: TextStyle(color: Colors.green[700], fontSize: 13)),
              ),

            // Amount
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _currency,
                      underline: const SizedBox(),
                      items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                // Quick amounts
                Wrap(spacing: 8, children: [10, 25, 50, 100, 250].map((a) =>
                  ActionChip(
                    label: Text('$_currency $a'),
                    onPressed: () => setState(() => _amountCtrl.text = a.toString()),
                  ),
                ).toList()),
              ]),
            ),

            const SizedBox(height: 16),

            // To account
            if (_accounts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Credit to', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
                      DropdownMenuItem(value: a['id'], child: Text('${a['name'] ?? a['account_number']} (${a['currency']})', style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                ]),
              ),

            const SizedBox(height: 16),

            // Payment methods info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800])),
                const SizedBox(height: 8),
                _methodRow('💳', 'Visa, Mastercard, Amex'),
                _methodRow('🏦', 'Bank Transfer (SEPA, FPS, ACH)'),
                _methodRow('📱', 'Mobile Money (M-Pesa, MTN, etc.)'),
                _methodRow('🔄', 'USSD'),
              ]),
            ),

            const SizedBox(height: 24),

            // Top Up button
            GestureDetector(
              onTap: _loading ? null : _topUp,
              child: Container(
                height: 52, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: _loading
                    ? [Colors.grey[400]!, Colors.grey[400]!]
                    : [const Color(0xFF1a56db), const Color(0xFF7c3aed)]),
                ),
                child: Center(child: Text(
                  _loading ? 'Processing...' : 'Top Up via Flutterwave',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodRow(String icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.blue[700])),
      ]),
    );
  }
}
