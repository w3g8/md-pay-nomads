import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});
  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  String? _nationality;
  int? _accountId;
  List<dynamic> _accounts = [];
  int _step = 0; // 0=select, 1=docs, 2=pay, 3=tracking
  bool _loading = false;
  String? _error;
  String? _submissionId;

  static const _countries = {
    'UK': {'price': 199, 'time': '3-6 weeks', 'flag': '\u{1F1EC}\u{1F1E7}'},
    'US': {'price': 249, 'time': '6-8 weeks', 'flag': '\u{1F1FA}\u{1F1F8}'},
    'Ireland': {'price': 179, 'time': '4-8 weeks', 'flag': '\u{1F1EE}\u{1F1EA}'},
    'Australia': {'price': 199, 'time': '3-6 weeks', 'flag': '\u{1F1E6}\u{1F1FA}'},
    'Canada': {'price': 229, 'time': '4-6 weeks', 'flag': '\u{1F1E8}\u{1F1E6}'},
    'Germany': {'price': 149, 'time': '4-6 weeks', 'flag': '\u{1F1E9}\u{1F1EA}'},
    'France': {'price': 149, 'time': '2-4 weeks', 'flag': '\u{1F1EB}\u{1F1F7}'},
    'Netherlands': {'price': 149, 'time': '5 days', 'flag': '\u{1F1F3}\u{1F1F1}'},
    'Italy': {'price': 149, 'time': '2-4 weeks', 'flag': '\u{1F1EE}\u{1F1F9}'},
    'Spain': {'price': 149, 'time': '1-2 weeks', 'flag': '\u{1F1EA}\u{1F1F8}'},
  };

  @override
  void initState() {
    super.initState();
    WalletService().getAccounts().then((a) => setState(() => _accounts = a)).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passport Renewal'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SafeArea(child: IndexedStack(index: _step, children: [_selectPage(), _docsPage(), _payPage(), _trackPage()])),
    );
  }

  Widget _btn(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: onTap == null ? [Colors.grey[400]!, Colors.grey[400]!] : [const Color(0xFF1a56db), const Color(0xFF7c3aed)])),
      child: Center(child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
    ),
  );

  Widget _selectPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Select Nationality', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    ..._countries.entries.map((e) => _countryTile(e.key, e.value)),
    if (_nationality != null) ...[const SizedBox(height: 24), _btn('Continue to Documents', () => setState(() => _step = 1))],
  ]);

  Widget _countryTile(String name, Map<String, dynamic> info) => GestureDetector(
    onTap: () => setState(() => _nationality = name),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _nationality == name ? const Color(0xFF1a56db) : Colors.grey[200]!, width: _nationality == name ? 2 : 1),
        color: _nationality == name ? const Color(0xFF1a56db).withAlpha(12) : Colors.white,
      ),
      child: Row(children: [
        Text(info['flag'] as String, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text('${info['time']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ])),
        Text('\u20AC${info['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1a56db))),
      ]),
    ),
  );

  Widget _docsPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Upload Documents', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text('Documents stored securely in SecureVault', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
    const SizedBox(height: 20),
    _docTile('Current Passport', 'Front page scan or photo', Icons.document_scanner),
    _docTile('New Passport Photo', 'White background, no glasses, face centered', Icons.photo_camera),
    _docTile('Proof of Address', 'Utility bill or bank statement', Icons.home),
    _docTile('Supporting Documents', 'Birth cert, deed poll, etc.', Icons.folder_open),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(Icons.lock, color: Colors.green[700], size: 20), const SizedBox(width: 8),
        Expanded(child: Text('Encrypted with AES-256 via SecureVault', style: TextStyle(color: Colors.green[700], fontSize: 12)))])),
    const SizedBox(height: 24),
    _btn('Review & Pay', () => setState(() => _step = 2)),
  ]);

  Widget _docTile(String title, String hint, IconData icon) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF1a56db), size: 28),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(hint, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ])),
      const Icon(Icons.add_circle_outline, color: Color(0xFF1a56db)),
    ]),
  );

  Widget _payPage() {
    final info = _countries[_nationality];
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Confirm & Pay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Column(children: [
          _row('Country', '${info?['flag']} $_nationality'),
          _row('Processing', '${info?['time']}'),
          const Divider(height: 20),
          _row('Service Fee', '\u20AC${info?['price']}', bold: true, big: true),
        ])),
      const SizedBox(height: 16),
      const Text('Pay From', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(value: _accountId,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
          DropdownMenuItem(value: a['id'], child: Text('${a['name'] ?? a['account_number']} - ${a['currency']}', style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _accountId = v)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
      const SizedBox(height: 24),
      _btn(_loading ? 'Processing...' : 'Pay \u20AC${info?['price']} Now', _loading ? null : () async {
        if (_accountId == null) { setState(() => _error = 'Select an account'); return; }
        setState(() { _loading = true; _error = null; });
        try {
          final res = await WalletService().submitPassportRenewal({'nationality': _nationality, 'account_id': _accountId});
          setState(() { _submissionId = res['submission_id'] ?? 'PP-${DateTime.now().millisecondsSinceEpoch}'; _step = 3; });
        } catch (e) { setState(() => _error = e.toString()); }
        setState(() => _loading = false);
      }),
    ]);
  }

  Widget _row(String l, String r, {bool bold = false, bool big = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.grey[600], fontSize: big ? 16 : 14)),
      Text(r, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: big ? 18 : 14, color: bold ? const Color(0xFF1a56db) : null)),
    ]),
  );

  Widget _trackPage() => ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 40),
        const SizedBox(height: 12),
        const Text('Renewal Submitted!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Ref: ${_submissionId ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    const SizedBox(height: 24),
    _statusRow('Submitted', true), _statusRow('Documents Verified', false), _statusRow('Processing', false),
    _statusRow('Shipped', false), _statusRow('Delivered', false),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(Icons.notifications_active, color: Colors.blue[700]), const SizedBox(width: 8),
        Expanded(child: Text("We'll notify you at each step", style: TextStyle(color: Colors.blue[700], fontSize: 13)))])),
  ]);

  Widget _statusRow(String label, bool done) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.grey[300], size: 28),
    const SizedBox(width: 16), Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: done ? Colors.black : Colors.grey[400])),
  ]));
}
