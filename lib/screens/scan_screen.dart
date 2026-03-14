import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/emvco_parser.dart';
import '../services/wallet_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum ScanStep { idle, scanning, merchant, amount, confirm, done }

class _ScanScreenState extends State<ScanScreen> {
  ScanStep _step = ScanStep.idle;
  QRPhData? _merchant;
  final _amountCtrl = TextEditingController();
  String _paymentType = 'purchase';
  int? _selectedAccountId;
  List<dynamic> _accounts = [];
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _receipt;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await WalletService().getAccounts();
      setState(() {});
    } catch (_) {}
  }

  void _onScan(String raw) {
    final parsed = parseQRPh(raw);
    if (parsed == null) {
      setState(() => _error = 'Not a valid QR Ph code');
      return;
    }
    setState(() {
      _merchant = parsed;
      if (parsed.amount != null) _amountCtrl.text = parsed.amount!.toStringAsFixed(2);
      _step = ScanStep.merchant;
    });
  }

  Future<void> _confirmPayment() async {
    if (_merchant == null || _selectedAccountId == null || _amountCtrl.text.isEmpty) return;
    setState(() { _submitting = true; _error = null; });
    try {
      final res = await WalletService().createQRPayment(
        sourceAccountId: _selectedAccountId!,
        merchantName: _merchant!.merchantName,
        merchantCity: _merchant!.merchantCity,
        merchantId: _merchant!.merchantId,
        acquirerBic: _merchant!.acquirerBIC,
        mcc: _merchant!.mcc,
        amount: double.parse(_amountCtrl.text),
        currency: _merchant!.currency,
        paymentType: _paymentType,
        qrRawData: _merchant!.rawData,
      );
      setState(() { _receipt = res; _step = ScanStep.done; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _step = ScanStep.idle;
      _merchant = null;
      _amountCtrl.clear();
      _receipt = null;
      _error = null;
      _paymentType = 'purchase';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == ScanStep.scanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _step = ScanStep.idle)),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) _onScan(code);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Pay')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _error = null)),
                ]),
              ),

            if (_step == ScanStep.idle) ...[
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(colors: [Color(0xFF1a56db), Color(0xFF7c3aed)]),
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: Text('Point your camera at a QR Ph code', style: TextStyle(fontSize: 15, color: Colors.black54))),
              const SizedBox(height: 8),
              Center(child: Text('Works with GCash, Maya, BDO, BPI, RCBC', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
              const SizedBox(height: 32),
              _gradientButton('Open Scanner', Icons.camera_alt, () => setState(() => _step = ScanStep.scanning)),
            ],

            if (_step == ScanStep.merchant && _merchant != null) ...[
              _merchantCard(),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _actionCard('Pay', Icons.qr_code, Colors.blue, () {
                  setState(() { _paymentType = 'purchase'; _step = ScanStep.amount; });
                })),
                const SizedBox(width: 12),
                Expanded(child: _actionCard('Get Cash', Icons.money, Colors.green, () {
                  setState(() { _paymentType = 'cashback'; _step = ScanStep.amount; });
                })),
              ]),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _reset, child: const Text('Scan Another')),
            ],

            if (_step == ScanStep.amount && _merchant != null) ...[
              _merchantSummary(),
              const SizedBox(height: 16),
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_paymentType == 'purchase' ? 'Payment Amount' : 'Cash Amount',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !(_merchant!.initiationMethod == 'dynamic' && _merchant!.amount != null),
                  decoration: InputDecoration(
                    prefixText: '${_merchant!.currency} ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('From Account', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
                    DropdownMenuItem(value: a['id'], child: Text('${a['name'] ?? a['account_number']} — ${a['currency']} ${(a['available_balance'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              ])),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = ScanStep.merchant), child: const Text('Back'))),
                const SizedBox(width: 12),
                Expanded(child: _gradientButton('Review', Icons.arrow_forward, () {
                  if (_amountCtrl.text.isNotEmpty && _selectedAccountId != null) {
                    setState(() => _step = ScanStep.confirm);
                  }
                })),
              ]),
            ],

            if (_step == ScanStep.confirm && _merchant != null) ...[
              _card(child: Column(children: [
                const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Divider(height: 24),
                _detailRow('Merchant', _merchant!.merchantName),
                _detailRow('Location', _merchant!.merchantCity),
                _detailRow('Type', _merchant!.mccDescription),
                const Divider(),
                _detailRow('Amount', '${_merchant!.currency} ${double.parse(_amountCtrl.text).toStringAsFixed(2)}',
                    bold: true, fontSize: 18),
              ])),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = ScanStep.amount), child: const Text('Back'))),
                const SizedBox(width: 12),
                Expanded(child: _gradientButton(
                  _submitting ? 'Processing...' : (_paymentType == 'purchase' ? 'Pay Now' : 'Confirm Cash'),
                  null, _submitting ? null : _confirmPayment,
                )),
              ]),
            ],

            if (_step == ScanStep.done && _receipt != null && _merchant != null) ...[
              const SizedBox(height: 40),
              const Center(child: CircleAvatar(radius: 36, backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 40))),
              const SizedBox(height: 16),
              Center(child: Text(_paymentType == 'purchase' ? 'Payment Successful' : 'Cash Withdrawal Confirmed',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              _card(child: Column(children: [
                _detailRow('Merchant', _merchant!.merchantName),
                _detailRow('Amount', '${_merchant!.currency} ${(_receipt!['amount'] ?? 0).toStringAsFixed(2)}', bold: true),
                if ((_receipt!['fee_amount'] ?? 0) > 0)
                  _detailRow('Fee', '${_merchant!.currency} ${(_receipt!['fee_amount']).toStringAsFixed(2)}'),
                _detailRow('Reference', _receipt!['reference'] ?? ''),
              ])),
              if (_paymentType == 'cashback')
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
                  child: const Text('Show this screen to the merchant to receive your cash.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 13)),
                ),
              const SizedBox(height: 24),
              _gradientButton('Done', null, _reset),
            ],
          ],
        ),
      ),
    );
  }

  Widget _merchantCard() {
    return _card(
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.store, color: Colors.blue[600]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_merchant!.merchantName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_merchant!.merchantCity.isEmpty ? 'Philippines' : _merchant!.merchantCity} — ${_merchant!.mccDescription}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            _chip(bicLabel(_merchant!.acquirerBIC), Colors.blue),
            _chip(_merchant!.currency, Colors.green),
            if (_merchant!.amount != null) _chip('Fixed: ${_merchant!.currency} ${_merchant!.amount!.toStringAsFixed(2)}', Colors.amber),
          ]),
        ])),
      ]),
    );
  }

  Widget _merchantSummary() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${_paymentType == 'purchase' ? 'Pay' : 'Get Cash from'} ${_merchant!.merchantName}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      Text(_merchant!.merchantCity, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
    ]));
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _chip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color[50], borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color[700])),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: fontSize)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: fontSize)),
      ]),
    );
  }

  Widget _actionCard(String label, IconData icon, MaterialColor color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: _card(child: Column(children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ])),
    );
  }

  Widget _gradientButton(String text, IconData? icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: onTap == null
              ? [Colors.grey[400]!, Colors.grey[400]!]
              : [const Color(0xFF1a56db), const Color(0xFF7c3aed)]),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}
