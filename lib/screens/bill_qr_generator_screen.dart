import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/emvco_parser.dart';
import '../services/wallet_service.dart';

/// Hotelier/merchant screen: enter an amount, generate a dynamic EMVCo QR
/// with the exact amount embedded. Customer scans it and the amount auto-fills.
class BillQrGeneratorScreen extends StatefulWidget {
  const BillQrGeneratorScreen({super.key});

  @override
  State<BillQrGeneratorScreen> createState() => _BillQrGeneratorScreenState();
}

class _BillQrGeneratorScreenState extends State<BillQrGeneratorScreen> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Puerto Princesa');
  String _mcc = '7011'; // Hotel & Lodging default
  String? _accountNumber;
  List<dynamic> _accounts = [];
  String? _qrData;
  bool _fullscreen = false;

  final _mccOptions = [
    ('7011', 'Hotel & Lodging'),
    ('5812', 'Restaurant'),
    ('5814', 'Fast Food'),
    ('5411', 'Grocery'),
    ('5499', 'Convenience Store'),
    ('4121', 'Taxi & Rideshare'),
    ('7297', 'Massage & Spa'),
    ('5999', 'General Retail'),
    ('8999', 'Services'),
  ];

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

  void _generate() {
    if (_businessNameCtrl.text.isEmpty || _accountNumber == null || _amountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    // Build dynamic EMVCo QR with amount
    var emvco = generateQRPh(
      merchantName: _businessNameCtrl.text,
      merchantCity: _cityCtrl.text,
      merchantId: _accountNumber!,
      acquirerBIC: 'PNBMPHMM',
      mcc: _mcc,
      amount: amount,
    );

    // If reference provided, we need to insert additional data field (tag 62)
    // The generateQRPh already handles the basic structure, but we can
    // add a reference by re-building with reference in the raw data
    if (_referenceCtrl.text.isNotEmpty) {
      emvco = _addReference(emvco, _referenceCtrl.text);
    }

    setState(() => _qrData = emvco);
  }

  /// Insert bill reference into EMVCo additional data field (tag 62)
  String _addReference(String qrBase, String reference) {
    // Rebuild with additional data containing reference label (sub-tag 05)
    final ref = reference.length > 25 ? reference.substring(0, 25) : reference;
    final refTlv = '05${ref.length.toString().padLeft(2, '0')}$ref';
    final addlData = '62${refTlv.length.toString().padLeft(2, '0')}$refTlv';

    // Insert before CRC (last 8 chars = "6304" + 4 hex digits)
    final beforeCrc = qrBase.substring(0, qrBase.length - 8);
    final withAddl = '$beforeCrc$addlData${'6304'}';

    // Recompute CRC
    final crc = crc16ccitt(withAddl).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$withAddl$crc';
  }

  @override
  Widget build(BuildContext context) {
    if (_fullscreen && _qrData != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => setState(() => _fullscreen = false),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_businessNameCtrl.text,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('PHP ${double.parse(_amountCtrl.text).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1a56db))),
                  if (_referenceCtrl.text.isNotEmpty)
                    Text('Ref: ${_referenceCtrl.text}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: QrImageView(data: _qrData!, size: 280, version: QrVersions.auto),
                  ),
                  const SizedBox(height: 20),
                  Text('Customer scans to pay', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  Text('Tap anywhere to go back', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bill QR Generator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Generate a dynamic QR code with the exact bill amount. '
                  'Your customer scans it and the amount is auto-filled — no manual entry.',
                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Business name
            _label('Business Name'),
            TextField(
              controller: _businessNameCtrl,
              maxLength: 25,
              onChanged: (_) => setState(() {}),
              decoration: _inputDeco(hint: 'e.g. Palawan Beach Resort'),
            ),
            const SizedBox(height: 12),

            // City
            _label('City'),
            TextField(
              controller: _cityCtrl,
              maxLength: 15,
              decoration: _inputDeco(hint: 'Puerto Princesa'),
            ),
            const SizedBox(height: 12),

            // Receiving account
            _label('Receiving Account'),
            DropdownButtonFormField<String>(
              initialValue: _accountNumber,
              decoration: _inputDeco(),
              items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<String>>((a) =>
                DropdownMenuItem(value: a['account_number'].toString(),
                    child: Text('${a['name'] ?? a['account_number']} — ${a['currency']}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _accountNumber = v),
            ),
            const SizedBox(height: 12),

            // Business type
            _label('Business Type'),
            Wrap(spacing: 6, runSpacing: 6, children: _mccOptions.map((m) =>
              ChoiceChip(
                label: Text(m.$2, style: const TextStyle(fontSize: 12)),
                selected: _mcc == m.$1,
                onSelected: (_) => setState(() => _mcc = m.$1),
                selectedColor: const Color(0xFF1a56db).withAlpha(25),
              )).toList()),
            const SizedBox(height: 20),

            // Amount — prominent
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF1a56db), Color(0xFF7c3aed)]),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bill Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: const InputDecoration(
                    prefixText: 'PHP ',
                    prefixStyle: TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w500),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() => _qrData = null),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // Reference
            _label('Bill Reference (optional)'),
            TextField(
              controller: _referenceCtrl,
              maxLength: 25,
              decoration: _inputDeco(hint: 'Room 204, Booking #1234'),
            ),
            const SizedBox(height: 20),

            // Generate button
            _gradientButton(
              'Generate Bill QR',
              _businessNameCtrl.text.isNotEmpty && _accountNumber != null && _amountCtrl.text.isNotEmpty
                  ? _generate : null,
            ),

            // QR result
            if (_qrData != null) ...[
              const SizedBox(height: 24),

              // QR display
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _fullscreen = true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: QrImageView(data: _qrData!, size: 220, version: QrVersions.auto),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(_businessNameCtrl.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Center(child: Text('PHP ${double.parse(_amountCtrl.text).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1a56db)))),
              if (_referenceCtrl.text.isNotEmpty)
                Center(child: Text('Ref: ${_referenceCtrl.text}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]))),
              const SizedBox(height: 8),
              Center(child: Text('Tap QR for fullscreen',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]))),

              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrData!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR data copied!')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _gradientButton('Fullscreen', () => setState(() => _fullscreen = true))),
              ]),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dynamic QR', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[800], fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Amount PHP ${double.parse(_amountCtrl.text).toStringAsFixed(2)} is locked into this QR code. '
                      'The customer cannot change it when scanning.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700])),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
  );

  InputDecoration _inputDeco({String? hint}) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _gradientButton(String text, VoidCallback? onTap) {
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
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
      ),
    );
  }
}
