import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class VisaScreen extends StatefulWidget {
  const VisaScreen({super.key});
  @override
  State<VisaScreen> createState() => _VisaScreenState();
}

class _VisaScreenState extends State<VisaScreen> {
  String? _citizenship;
  String? _destination;
  int? _accountId;
  List<dynamic> _accounts = [];
  bool _insurance = false;
  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _submissionId;

  static const _visas = {
    'Portugal': {'type': 'D7 / Digital Nomad', 'income': 3040, 'duration': '12 months', 'fee': 199, 'cur': 'EUR'},
    'Spain': {'type': 'Digital Nomad Visa', 'income': 2520, 'duration': '1 year', 'fee': 199, 'cur': 'EUR'},
    'Croatia': {'type': 'Digital Nomad Visa', 'income': 2539, 'duration': '1 year', 'fee': 149, 'cur': 'EUR'},
    'Greece': {'type': 'Digital Nomad Visa', 'income': 3500, 'duration': '1 year', 'fee': 179, 'cur': 'EUR'},
    'Georgia': {'type': 'Remotely from Georgia', 'income': 0, 'duration': '1 year visa-free', 'fee': 49, 'cur': 'EUR'},
    'Thailand': {'type': 'LTR / DTV', 'income': 2000, 'duration': '5 years', 'fee': 179, 'cur': 'USD'},
    'Indonesia': {'type': 'B211A / DN Visa', 'income': 2000, 'duration': '6-12 months', 'fee': 149, 'cur': 'USD'},
    'Colombia': {'type': 'Digital Nomad Visa', 'income': 900, 'duration': '2 years', 'fee': 129, 'cur': 'USD'},
    'Mexico': {'type': 'Temporary Resident', 'income': 2600, 'duration': '1-4 years', 'fee': 149, 'cur': 'USD'},
    'Hungary': {'type': 'White Card', 'income': 2000, 'duration': '1 year', 'fee': 149, 'cur': 'EUR'},
    'Estonia': {'type': 'Digital Nomad Visa', 'income': 3500, 'duration': '1 year', 'fee': 149, 'cur': 'EUR'},
    'Brazil': {'type': 'Digital Nomad Visa', 'income': 1500, 'duration': '1 year', 'fee': 149, 'cur': 'USD'},
  };

  static const _nationalities = ['UK','US','Ireland','Australia','Canada','Germany','France','Netherlands','Italy','Spain','Portugal','Sweden','Norway','Denmark','Japan','South Korea','Singapore','New Zealand'];

  @override
  void initState() {
    super.initState();
    WalletService().getAccounts().then((a) => setState(() => _accounts = a)).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visa Application'), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: SafeArea(child: [_citizenPage(), _destPage(), _docsPage(), _payPage(), _trackPage()][_step]),
    );
  }

  Widget _btn(String text, VoidCallback? onTap) => GestureDetector(onTap: onTap, child: Container(
    height: 52, width: double.infinity,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: onTap == null ? [Colors.grey[400]!, Colors.grey[400]!] : [const Color(0xFF1a56db), const Color(0xFF7c3aed)])),
    child: Center(child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
      : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
  ));

  Widget _citizenPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('I am a citizen of', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(initialValue: _citizenship,
      decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), hintText: 'Select nationality'),
      items: _nationalities.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
      onChanged: (v) => setState(() => _citizenship = v)),
    if (_citizenship != null) ...[const SizedBox(height: 24), _btn('Continue', () => setState(() => _step = 1))],
  ]);

  Widget _destPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('I want to go to', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    ..._visas.entries.map((e) => _visaTile(e.key, e.value)),
    if (_destination != null) ...[const SizedBox(height: 24), _btn('Continue', () => setState(() => _step = 2))],
  ]);

  Widget _visaTile(String country, Map<String, dynamic> info) => GestureDetector(
    onTap: () => setState(() => _destination = country),
    child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _destination == country ? const Color(0xFF1a56db) : Colors.grey[200]!, width: _destination == country ? 2 : 1),
        color: _destination == country ? const Color(0xFF1a56db).withAlpha(12) : Colors.white),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(country, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text('${info['type']} \u2022 ${info['duration']}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if ((info['income'] as int) > 0) Text('Min. ${info['cur']}\u202F${info['income']}/mo income', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        ])),
        Text('${info['cur']}\u202F${info['fee']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1a56db))),
      ]),
    ),
  );

  Widget _docsPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Document Checklist', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    Text('$_citizenship \u2192 $_destination', style: TextStyle(color: Colors.grey[500])),
    const SizedBox(height: 20),
    _check('Valid passport (6+ months validity)'),
    _check('Passport-sized photos (4x)'),
    _check('Proof of income / bank statements'),
    _check('Health insurance certificate'),
    _check('Clean criminal record'),
    _check('Proof of accommodation'),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [Icon(Icons.lightbulb, color: Colors.amber[700], size: 20), const SizedBox(width: 8),
        Expanded(child: Text('Tap "Generate Income Proof" to create a verified statement from your wallet transactions', style: TextStyle(color: Colors.amber[800], fontSize: 12)))])),
    const SizedBox(height: 8),
    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.description), label: const Text('Generate Income Proof'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    const SizedBox(height: 16),
    SwitchListTile(title: const Text('Bundle SafetyWing Insurance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text('\$45/mo \u2014 medical, evacuation, luggage', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      value: _insurance, onChanged: (v) => setState(() => _insurance = v), activeColor: const Color(0xFF1a56db)),
    const SizedBox(height: 24),
    _btn('Review & Pay', () => setState(() => _step = 3)),
  ]);

  Widget _check(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
    Icon(Icons.check_box_outline_blank, color: Colors.grey[400], size: 22), const SizedBox(width: 12),
    Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
  ]));

  Widget _payPage() {
    final info = _visas[_destination] ?? {};
    final fee = info['fee'] ?? 0;
    final ins = _insurance ? 45 : 0;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Confirm & Pay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          _row('From', _citizenship ?? ''), _row('To', _destination ?? ''),
          _row('Visa', '${info['type'] ?? ''}'), const Divider(height: 20),
          _row('Application Fee', '${info['cur'] ?? 'EUR'}\u202F$fee'),
          if (_insurance) _row('SafetyWing', '\$45/mo'),
          const Divider(height: 20),
          _row('Total Due Now', '${info['cur'] ?? 'EUR'}\u202F${(fee is int ? fee : 0) + ins}', bold: true),
        ])),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(initialValue: _accountId,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), labelText: 'Pay from account'),
        items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
          DropdownMenuItem(value: a['id'], child: Text('${a['name'] ?? a['account_number']} - ${a['currency']}', style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _accountId = v)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Colors.red[700]))),
      const SizedBox(height: 24),
      _btn('Pay & Apply', _loading ? null : () async {
        if (_accountId == null) { setState(() => _error = 'Select an account'); return; }
        setState(() { _loading = true; _error = null; });
        try {
          final res = await WalletService().submitVisaApplication({'citizenship': _citizenship, 'destination': _destination, 'account_id': _accountId, 'insurance': _insurance});
          setState(() { _submissionId = res['submission_id'] ?? 'VA-${DateTime.now().millisecondsSinceEpoch}'; _step = 4; });
        } catch (e) { setState(() => _error = e.toString()); }
        setState(() => _loading = false);
      }),
    ]);
  }

  Widget _row(String l, String r, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(color: Colors.grey[600])),
      Text(r, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: bold ? const Color(0xFF1a56db) : null)),
    ]));

  Widget _trackPage() => ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 40), const SizedBox(height: 12),
        const Text('Application Submitted!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$_citizenship \u2192 $_destination', style: const TextStyle(color: Colors.white70)),
        Text('Ref: ${_submissionId ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
    const SizedBox(height: 24),
    _statusRow('Submitted', true), _statusRow('Documents Verified', false),
    _statusRow('Under Review', false), _statusRow('Approved', false), _statusRow('Visa Issued', false),
  ]);

  Widget _statusRow(String label, bool done) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Colors.green : Colors.grey[300], size: 28),
    const SizedBox(width: 16), Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: done ? Colors.black : Colors.grey[400])),
  ]));
}
